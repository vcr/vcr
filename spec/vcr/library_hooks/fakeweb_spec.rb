require 'spec_helper'

describe "FakeWeb hook", :with_monkey_patches => :fakeweb do
  after(:each) do
    ::FakeWeb.clean_registry
  end

  def disable_real_connections
    ::FakeWeb.allow_net_connect = false
    ::FakeWeb::NetConnectNotAllowedError
  end

  def enable_real_connections
    ::FakeWeb.allow_net_connect = true
  end

  def directly_stub_request(method, url, response_body)
    ::FakeWeb.register_uri(method, url, :body => response_body)
  end

  it_behaves_like 'a hook into an HTTP library', :fakeweb, 'net/http'

  describe "some specific Net::HTTP edge cases" do
    before(:each) do
      VCR.stub(:real_http_connections_allowed? => true)
    end

    it 'records the request body when using #post_form' do
      VCR.should_receive(:record_http_interaction) do |interaction|
        interaction.request.body.should eq("q=ruby")
      end

      uri = URI("http://localhost:#{VCR::SinatraApp.port}/foo")
      Net::HTTP.post_form(uri, 'q' => 'ruby')
    end

    it "does not record headers for which Net::HTTP sets defaults near the end of the real request" do
      VCR.should_receive(:record_http_interaction) do |interaction|
        interaction.request.headers.should_not have_key('content-type')
        interaction.request.headers.should_not have_key('host')
      end
      Net::HTTP.new('localhost', VCR::SinatraApp.port).send_request('POST', '/', '', { 'x-http-user' => 'me' })
    end

    it "records headers for which Net::HTTP usually sets defaults when the user manually sets their values" do
      VCR.should_receive(:record_http_interaction) do |interaction|
        interaction.request.headers['content-type'].should eq(['foo/bar'])
        interaction.request.headers['host'].should eq(['my-example.com'])
      end
      Net::HTTP.new('localhost', VCR::SinatraApp.port).send_request('POST', '/', '', { 'Content-Type' => 'foo/bar', 'Host' => 'my-example.com' })
    end

    def perform_get_with_returning_block
      Net::HTTP.new('localhost', VCR::SinatraApp.port).request(Net::HTTP::Get.new('/', {})) do |response|
        return response
      end
    end

    it 'records the interaction when Net::HTTP#request is called with a block with a return statement' do
      VCR.should_receive(:record_http_interaction).once
      perform_get_with_returning_block.body.should eq("GET to root")
    end

    def make_post_request
      Net::HTTP.new('localhost', VCR::SinatraApp.port).post('/record-and-playback', '')
    end

    it 'records the interaction only once, even when Net::HTTP internally recursively calls #request' do
      VCR.should_receive(:record_http_interaction).once
      make_post_request
    end

    it 'properly returns the response body for a post request when recording, stubbing or ignoring the request' do
      recorded_body = nil
      VCR.use_cassette("new_cassette", :record => :once) do
        recorded_body = make_post_request.body
        recorded_body.should match(/Response \d+/)
      end

      VCR.use_cassette("new_cassette", :record => :once) do
        make_post_request.body.should eq(recorded_body)
      end

      VCR.configuration.ignore_request { |r| true }
      ignored_body = make_post_request.body
      ignored_body.should_not eq(recorded_body)
      ignored_body.should match(/Response \d+/)
    end

    context 'when the same Net::HTTP request object is used twice' do
      let(:uri)  { URI("http://localhost:#{VCR::SinatraApp.port}/foo") }
      let(:http) { Net::HTTP.new(uri.host, uri.port) }

      it 'raises an UnhandledHTTPRequestError when using a cassette that only recorded one request' do
        VCR.use_cassette("new_cassette", :record => :once) do
          request = Net::HTTP::Get.new(uri.request_uri)
          http.request(request)
        end

        VCR.use_cassette("new_cassette", :record => :once) do
          request = Net::HTTP::Get.new(uri.request_uri)
          http.request(request)
          http.request(request)
        end
      end
    end
  end

  describe "VCR.configuration.after_library_hooks_loaded hook" do
    let(:run_hook) { $fakeweb_after_loaded_hook.conditionally_invoke }

    context 'when WebMock has been loaded' do
      before(:each) { defined?(WebMock).should be_true }

      it 'raises an error since FakeWeb and WebMock cannot both be used simultaneously' do
        expect { run_hook }.to raise_error(ArgumentError, /cannot use both/)
      end
    end

    context 'when WebMock has not been loaded' do
      let!(:orig_webmock_constant) { ::WebMock }
      before(:each) { Object.send(:remove_const, :WebMock) }
      after(:each)  { ::WebMock = orig_webmock_constant }

      it 'does not raise an error' do
        run_hook # should not raise an error
      end
    end
  end

  describe "when a SocketError occurs" do
    before(:each) do
      VCR.configuration.ignore_request { |r| true }
    end

    it_behaves_like "request hooks", :fakeweb, :ignored do
      undef assert_expected_response
      def assert_expected_response(response)
        response.should be_nil
      end

      undef make_request
      def make_request(disabled = false)
        ::Net::HTTP.any_instance.stub(:request_without_vcr).and_raise(SocketError)
        expect {
          ::Net::HTTP.get_response(URI(request_url))
        }.to raise_error(SocketError)
      end
    end
  end

  describe "when VCR is turned off" do
    it 'allows white listed connections' do
      ::FakeWeb.allow_net_connect = %r[localhost]

      VCR.turn_off!

      uri = URI("http://localhost:#{VCR::SinatraApp.port}/foo")
      Net::HTTP.get(uri).should eq("FOO!")
    end
  end
end
