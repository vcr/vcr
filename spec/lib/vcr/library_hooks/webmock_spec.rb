require 'spec_helper'
require 'support/shared_example_groups/excon'

RSpec.describe "WebMock hook", with_monkey_patches: :webmock do
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
    ::WebMock.stub_request(method, url).to_return(body: response_body)
  end

  describe "our WebMock.after_request hook" do
    let(:webmock_request) { ::WebMock::RequestSignature.new(:get, "http://foo.com/", body: "", headers: {}) }
    let(:webmock_response) { ::WebMock::Response.new(body: 'OK', status: [200, '']) }

    def run_after_request_callback
      ::WebMock::CallbackRegistry.invoke_callbacks(
        { real_request: true },
        webmock_request,
        webmock_response)
    end

    it 'removes the @__typed_vcr_request instance variable so as not to pollute the webmock object' do
      request = VCR::Request::Typed.new(VCR::Request, :ignored?)
      webmock_request.instance_variable_set(:@__typed_vcr_request, request)

      run_after_request_callback
      expect(webmock_request.instance_variables.map(&:to_sym)).not_to include(:@__typed_vcr_request)
    end

    context "when there'ss a bug and the request does not have the @__typed_vcr_request in the after_request callbacks" do
      let(:warner) { VCR::LibraryHooks::WebMock }
      before { allow(warner).to receive(:warn) }

      it 'records the HTTP interaction properly' do
        expect(VCR).to receive(:record_http_interaction) do |i|
          expect(i.request.uri).to eq("http://foo.com/")
          expect(i.response.body).to eq("OK")
        end

        run_after_request_callback
      end

      it 'invokes the after_http_request hook with an :unknown request' do
        request = nil
        VCR.configuration.after_http_request do |req, res|
          request = req
        end

        run_after_request_callback
        expect(request.uri).to eq("http://foo.com/")
        expect(request.type).to eq(:unknown)
      end

      it 'prints a warning' do
        expect(warner).to receive(:warn).at_least(:once).with(/bug.*after_request/)

        run_after_request_callback
      end
    end
  end

  describe "inserting a cassette after WebMock.disable!" do
    def make_request
      Net::HTTP.get_response(URI("http://localhost:#{VCR::SinatraApp.port}/foo")).body
    end

    def webmock_enabled?
      !::Net::HTTP.equal?(::WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetHTTP)
    end

    before { ::WebMock.disable! }

    after do
      ::WebMock::HttpLibAdapterRegistry.instance.each_adapter { |_name, adapter| adapter.enable! }
      VCR::LibraryHooks::WebMock.forget_reenabled_webmock
    end

    it "re-enables WebMock so that VCR handles requests again" do
      VCR.use_cassette("example", record: :none) do
        expect(webmock_enabled?).to be true
        expect { make_request }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end
    end

    it "disables WebMock again when that cassette is ejected" do
      VCR.use_cassette("outer", record: :none) do
        VCR.use_cassette("inner", record: :none) { }
        expect(webmock_enabled?).to be true
      end

      expect(webmock_enabled?).to be false
      expect(make_request).to eq("FOO!")
    end

    it "keeps WebMock enabled until the cassettes of every thread are ejected" do
      inserted, eject = Queue.new, Queue.new
      VCR.insert_cassette("main thread", record: :none)
      other_thread = Thread.new do
        VCR.use_cassette("other thread", record: :none) do
          inserted << true
          eject.pop
        end
      end

      begin
        inserted.pop
        VCR.eject_cassette
        expect(webmock_enabled?).to be true
      ensure
        eject << true
        other_thread.join
      end

      expect(webmock_enabled?).to be false
    end

    it "leaves WebMock enabled when the user enabled it while the cassette was in" do
      VCR.use_cassette("example", record: :none) { ::WebMock.enable! }

      expect(webmock_enabled?).to be true
    end

    it "restores the adapters a partial WebMock.disable! left enabled" do
      original_http_client = ::WebMock::HttpLibAdapters::HTTPClientAdapter::OriginalHttpClient
      ::WebMock.disable!(except: [:httpclient])

      VCR.use_cassette("example", record: :none) do
        expect(webmock_enabled?).to be true
      end

      expect(webmock_enabled?).to be false
      expect(::HTTPClient).not_to equal(original_http_client)
    end

    it "re-enables WebMock after a partial WebMock.disable! that leaves Net::HTTP hooked" do
      ::WebMock.disable!(except: [:net_http])

      VCR.use_cassette("example", record: :none) do
        expect {
          HTTPClient.new.get("http://localhost:#{VCR::SinatraApp.port}/foo")
        }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end

      expect(HTTPClient.new.get("http://localhost:#{VCR::SinatraApp.port}/foo").body).to eq("FOO!")
    end

    it "leaves Net::HTTP untouched after WebMock.enable!(except: [:net_http])" do
      ::WebMock.enable!(except: [:net_http])

      VCR.use_cassette("example", record: :none) do
        expect(webmock_enabled?).to be false
        expect(make_request).to eq("FOO!")
      end

      expect(webmock_enabled?).to be false
    end

    it "lets a signal handler call WebMock.disable!", if: Signal.list.key?("USR1") do
      disabled = false
      previous_handler = Signal.trap("USR1") do
        ::WebMock.disable!
        disabled = true
      end

      Process.kill("USR1", Process.pid)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
      sleep 0.01 until disabled || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      expect(disabled).to be true
    ensure
      Signal.trap("USR1", previous_handler)
    end

    it "does not insert the cassette when re-enabling WebMock fails" do
      allow(::WebMock).to receive(:enable!).and_raise("boom")

      expect { VCR.insert_cassette("example") }.to raise_error("boom")
      expect(VCR.current_cassette).to be_nil
    end

    it "keeps the WebMock adapters of libraries VCR hooks into directly disabled" do
      expect(::WebMock).to receive(:enable!).with(except: [:excon, :typhoeus])

      VCR.insert_cassette("example")
    end

    it "leaves WebMock disabled when the cassette is ignored because VCR is turned off" do
      VCR.turned_off(ignore_cassettes: true) do
        VCR.insert_cassette("example")
      end

      expect(webmock_enabled?).to be false
    end
  end

  it "does not re-enable WebMock on cassette insertion when it is already enabled" do
    expect(::WebMock).not_to receive(:enable!)

    VCR.insert_cassette("example")
  end

  http_libs = %w[net/http patron httpclient em-http-request curb typhoeus excon]
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
    describe "using #{adapter_module.http_library_name}", unless: http_lib_unsupported do
      include adapter_module

      let!(:request_url) { "http://localhost:#{VCR::SinatraApp.port}/foo" }

      context 'when real connections are disabled and VCR is turned off' do
        it 'can allow connections to localhost' do
          VCR.turn_off!
          disable_real_connections(allow_localhost: true)

          expect {
            make_http_request(:get, request_url)
          }.to_not raise_error
        end

        it 'can allow connections to matching urls' do
          VCR.turn_off!
          disable_real_connections(allow: /foo/)

          expect {
            make_http_request(:get, request_url)
          }.to_not raise_error
        end
      end
    end
  end

  it_behaves_like "Excon streaming"
end

