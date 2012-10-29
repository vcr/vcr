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

  describe "our WebMock.after_request hook" do
    let(:webmock_request) { ::WebMock::RequestSignature.new(:get, "http://foo.com/", :body => "", :headers => {}) }
    let(:webmock_response) { ::WebMock::Response.new(:body => 'OK', :status => [200, '']) }

    def run_after_request_callback
      ::WebMock::CallbackRegistry.invoke_callbacks(
        { :real_request => true },
        webmock_request,
        webmock_response)
    end

    it 'removes the @__typed_vcr_request instance variable so as not to pollute the webmock object' do
      request = VCR::Request::Typed.new(VCR::Request, :ignored?)
      webmock_request.instance_variable_set(:@__typed_vcr_request, request)

      run_after_request_callback
      webmock_request.instance_variables.map(&:to_sym).should_not include(:@__typed_vcr_request)
    end

    context "when there'ss a bug and the request does not have the @__typed_vcr_request in the after_request callbacks" do
      let(:warner) { VCR::LibraryHooks::WebMock }
      before { warner.stub(:warn) }

      it 'records the HTTP interaction properly' do
        VCR.should_receive(:record_http_interaction) do |i|
          i.request.uri.should eq("http://foo.com/")
          i.response.body.should eq("OK")
        end

        run_after_request_callback
      end

      it 'invokes the after_http_request hook with an :unknown request' do
        request = nil
        VCR.configuration.after_http_request do |req, res|
          request = req
        end

        run_after_request_callback
        request.uri.should eq("http://foo.com/")
        request.type.should eq(:unknown)
      end

      it 'prints a warning' do
        warner.should_receive(:warn).at_least(:once).with(/bug.*after_request/)

        run_after_request_callback
      end
    end
  end

  http_libs = %w[net/http patron httpclient em-http-request curb typhoeus excon]
  http_libs.delete('patron') if RUBY_VERSION == '1.8.7'
  http_libs.each do |lib|
    other = []
    other << :status_message_not_exposed if lib == 'excon'
    it_behaves_like 'a hook into an HTTP library', :webmock, lib, *other do
      if lib == 'net/http'
        def normalize_request_headers(headers)
          headers.merge(DEFAULT_REQUEST_HEADERS)
        end
      end
    end

    http_lib_unsupported = (RUBY_INTERPRETER != :mri && lib =~ /(typhoeus|curb|patron|em-http)/)

    adapter_module = HTTP_LIBRARY_ADAPTERS.fetch(lib)
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
