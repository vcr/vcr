require 'spec_helper'
require 'vcr/library_hooks/faraday'

describe VCR::Middleware::Faraday do
  %w[ typhoeus net_http patron ].each do |lib|
    it_behaves_like 'a hook into an HTTP library', "faraday (w/ #{lib})",
      :status_message_not_exposed,
      :does_not_support_rotating_responses,
      :not_disableable
  end

  it_performs('version checking', 'Faraday',
    :valid    => %w[ 0.7.0 0.7.10 ],
    :too_low  => %w[ 0.6.9 0.5.99 ],
    :too_high => %w[ 0.8.0 1.0.0 ],
    :file     => 'vcr/middleware/faraday.rb'
  ) do
    before(:each) { @orig_version = Faraday::VERSION }
    after(:each)  { Faraday::VERSION = @orig_version }

    # Cannot be regular method def as that raises a "dynamic constant assignment" error
    define_method :stub_version do |version|
      ::Faraday::VERSION = version
    end
  end

  context 'when making parallel requests' do
    let(:parallel_manager)   { ::Faraday::Adapter::Typhoeus.setup_parallel_manager }
    let(:connection)         { ::Faraday.new { |b| b.adapter :typhoeus } }
    let!(:inserted_cassette) { VCR.insert_cassette('new_cassette') }

    it_behaves_like "after_http_request hook" do
      undef make_request
      def make_request(disabled = false)
        response = nil
        connection.in_parallel(parallel_manager) do
          response = connection.get(request_url)
        end
        response
      end

      it 'can be used to eject a cassette after the request is recorded' do
        VCR.configuration.after_http_request do |request|
          VCR.eject_cassette
        end

        VCR.should_receive(:record_http_interaction) do |interaction|
          VCR.current_cassette.should be(inserted_cassette)
        end

        make_request
        VCR.current_cassette.should be_nil
      end
    end
  end if defined?(::Typhoeus)
end
