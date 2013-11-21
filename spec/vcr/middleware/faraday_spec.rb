require 'spec_helper'
require 'vcr/library_hooks/faraday'

describe VCR::Middleware::Faraday do
  http_libs = %w[ typhoeus net_http patron ]
  http_libs.delete('patron') if RUBY_VERSION == '1.8.7'
  http_libs.each do |lib|
    it_behaves_like 'a hook into an HTTP library', :faraday, "faraday (w/ #{lib})",
      :status_message_not_exposed,
      :does_not_support_rotating_responses
  end

  context 'when performing a multipart upload' do
    let(:connection) do
      ::Faraday.new("http://localhost:#{VCR::SinatraApp.port}/") do |b|
        b.request :multipart
      end
    end

    def self.test_recording
      it 'records the request body correctly' do
        payload = { :file => Faraday::UploadIO.new(__FILE__, 'text/plain') }

        expect(VCR).to receive(:record_http_interaction) do |i|
          expect(i.request.headers['Content-Type'].first).to include("multipart")
          expect(i.request.body).to include(File.read(__FILE__))
        end

        VCR.use_cassette("upload") do
          connection.post '/files', payload
        end
      end
    end

    context 'when the net_http adapter is used' do
      before { connection.builder.adapter :net_http }
      test_recording
    end

    context 'when no adapter is used' do
      test_recording
    end
  end

  context 'when extending the response body with an extension module' do
    let(:connection) { ::Faraday.new("http://localhost:#{VCR::SinatraApp.port}/") }

    def process_response(response)
      response.body.extend Module.new { attr_accessor :_response }
      response.body._response = response
    end

    it 'does not record the body extensions to the cassette' do
      3.times do |i|
        VCR.use_cassette("hack", :record => :new_episodes) do
          response = connection.get("/foo")
          process_response(response)

          # Do something different after the first time to
          # ensure new interactions are added to an existing
          # cassette.
          if i > 1
            response = connection.get("/")
            process_response(response)
          end
        end
      end

      contents = VCR::Cassette.new("hack").send(:raw_cassette_bytes)
      expect(contents).not_to include("ruby/object:Faraday::Response")
    end
  end

  context 'when making parallel requests' do
    include VCRStubHelpers
    let(:connection)         { ::Faraday.new { |b| b.adapter :typhoeus } }
    let(:request_url) { "http://localhost:#{VCR::SinatraApp.port}/" }

    it 'works correctly with multiple parallel requests' do
      recorded, played_back = [1, 2].map do
        responses = []

        VCR.use_cassette("multiple_parallel") do
          connection.in_parallel do
            responses << connection.get(request_url)
            responses << connection.get(request_url)
          end
        end

        responses.map(&:body)
      end

      # there should be no blanks
      expect(recorded.select { |r| r.to_s == '' }).to eq([])
      expect(played_back).to eq(recorded)
    end

    shared_examples_for "exclusive library hook" do
      def make_request
        connection.in_parallel { connection.get(request_url) }
      end

      it 'makes the faraday middleware exclusively enabled for the duration of the request' do
        expect(VCR.library_hooks).not_to be_disabled(:fakeweb)

        hook_called = false
        VCR.configuration.after_http_request do
          hook_called = true
          expect(VCR.library_hooks).to be_disabled(:fakeweb)
        end

        make_request
        expect(VCR.library_hooks).not_to be_disabled(:fakeweb)
        expect(hook_called).to be true
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

    context "when another adapter is exclusive" do
      it 'still makes requests properly' do
        response = VCR.library_hooks.exclusively_enabled(:typhoeus) do
          Faraday.get("http://localhost:#{VCR::SinatraApp.port}/")
        end

        expect(response.body).to eq("GET to root")
      end
    end

    context 'for a recorded request' do
      let!(:inserted_cassette) { VCR.insert_cassette('new_cassette') }
      before(:each) { expect(VCR).to receive(:record_http_interaction) }
      it_behaves_like "exclusive library hook"
    end

    context 'for a disallowed request' do
      it_behaves_like "exclusive library hook" do
        undef make_request
        def make_request
          expect {
            connection.in_parallel { connection.get(request_url) }
          }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
        end
      end
    end

    it_behaves_like "request hooks", :faraday, :recordable do
      let!(:inserted_cassette) { VCR.insert_cassette('new_cassette') }

      undef make_request
      def make_request(disabled = false)
        response = nil
        connection.in_parallel do
          response = connection.get(request_url)
        end
        response
      end

      it 'can be used to eject a cassette after the request is recorded' do
        VCR.configuration.after_http_request { |request| VCR.eject_cassette }

        expect(VCR).to receive(:record_http_interaction) do |interaction|
          expect(VCR.current_cassette).to be(inserted_cassette)
        end

        make_request
        expect(VCR.current_cassette).to be_nil
      end
    end
  end if defined?(::Typhoeus)
end
