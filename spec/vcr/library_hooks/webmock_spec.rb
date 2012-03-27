require 'spec_helper'

describe "WebMock hook", :with_monkey_patches => :webmock do
  after(:each) do
    ::WebMock.reset!
  end

  def disable_real_connections(options = {})
    ::WebMock.disable_net_connect!(options)
    ::WebMock::NetConnectNotAllowedError
  end

  def enable_real_connections
    ::WebMock.allow_net_connect!
  end

  def directly_stub_request(method, url, response_body)
    ::WebMock.stub_request(method, url).to_return(:body => response_body)
  end

  %w[net/http patron httpclient em-http-request curb typhoeus excon].each do |lib|
    other = []
    other << :status_message_not_exposed if lib == 'excon'
    it_behaves_like 'a hook into an HTTP library', :webmock, lib, *other do
      if lib == 'net/http'
        def normalize_request_headers(headers)
          headers.merge(DEFAULT_REQUEST_HEADERS)
        end
      end
    end

    unless adapter_module = HTTP_LIBRARY_ADAPTERS[lib]
      raise ArgumentError.new("No http library adapter module could be found for #{lib}")
    end

    http_lib_unsupported = (RUBY_INTERPRETER != :mri && library =~ /(typhoeus|curb|patron|em-http)/)

    describe "using #{adapter_module.http_library_name}", :unless => http_lib_unsupported do
      include adapter_module

      let!(:request_url) { "http://localhost:#{VCR::SinatraApp.port}/foo" }

      context 'when real connections are disabled and VCR is turned off' do
        it 'can allow connections to localhost' do
          VCR.turn_off!
          unexpected_error = disable_real_connections(:allow_localhost => true)

          expect {
            make_http_request(:get, request_url)
          }.to_not raise_error(unexpected_error)
        end

        it 'can allow connections to matching urls' do
          VCR.turn_off!
          unexpected_error = disable_real_connections(:allow => /foo/)

          expect {
            make_http_request(:get, request_url)
          }.to_not raise_error(unexpected_error)
        end
      end
    end
  end
end
