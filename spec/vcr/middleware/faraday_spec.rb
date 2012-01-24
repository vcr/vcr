require 'spec_helper'
require 'vcr/library_hooks/faraday'

describe VCR::Middleware::Faraday do
  %w[ typhoeus net_http patron ].each do |lib|
    it_behaves_like 'a hook into an HTTP library', :faraday, "faraday (w/ #{lib})",
      :status_message_not_exposed,
      :does_not_support_rotating_responses,
      :not_disableable
  end

  context 'when making parallel requests' do
    include VCRStubHelpers
    let(:parallel_manager)   { ::Faraday::Adapter::Typhoeus.setup_parallel_manager }
    let(:connection)         { ::Faraday.new { |b| b.adapter :typhoeus } }

    shared_examples_for "exclusive library hook" do
      let(:request_url) { "http://localhost:#{VCR::SinatraApp.port}/" }

      def make_request
        connection.in_parallel(parallel_manager) { connection.get(request_url) }
      end

      it 'makes the faraday middleware exclusively enabled for the duration of the request' do
        VCR.library_hooks.should_not be_disabled(:fakeweb)

        hook_called = false
        VCR.configuration.after_http_request do
          hook_called = true
          VCR.library_hooks.should be_disabled(:fakeweb)
        end

        make_request
        VCR.library_hooks.should_not be_disabled(:fakeweb)
        hook_called.should be_true
      end
    end

    context 'for an ignored request' do
      before(:each) { VCR.configuration.ignore_request { true } }
      it_behaves_like "exclusive library hook"
    end

    context 'for a stubbed request' do
      it_behaves_like "exclusive library hook" do
        before(:each) do
          stub_requests([http_interaction(request_url)], [:method, :uri])
        end
      end
    end

    context 'for a recorded request' do
      let!(:inserted_cassette) { VCR.insert_cassette('new_cassette') }
      before(:each) { VCR.should_receive(:record_http_interaction) }
      it_behaves_like "exclusive library hook"
    end

    context 'for a disallowed request' do
      it_behaves_like "exclusive library hook" do
        undef make_request
        def make_request
          expect {
            connection.in_parallel(parallel_manager) { connection.get(request_url) }
          }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
        end
      end
    end

    it_behaves_like "request hooks", :faraday, :recordable do
      let!(:inserted_cassette) { VCR.insert_cassette('new_cassette') }

      undef make_request
      def make_request(disabled = false)
        response = nil
        connection.in_parallel(parallel_manager) do
          response = connection.get(request_url)
        end
        response
      end

      it 'can be used to eject a cassette after the request is recorded' do
        VCR.configuration.after_http_request { |request| VCR.eject_cassette }

        VCR.should_receive(:record_http_interaction) do |interaction|
          VCR.current_cassette.should be(inserted_cassette)
        end

        make_request
        VCR.current_cassette.should be_nil
      end
    end
  end if defined?(::Typhoeus)
end
