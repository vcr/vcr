require 'cgi'

NET_CONNECT_NOT_ALLOWED_ERROR = /An HTTP request has been made that VCR does not know how to handle/

shared_examples_for "a hook into an HTTP library" do |library_hook_name, library, *other|
  include HeaderDowncaser
  include VCRStubHelpers

  unless adapter_module = HTTP_LIBRARY_ADAPTERS[library]
    raise ArgumentError.new("No http library adapter module could be found for #{library}")
  end

  http_lib_unsupported = (RUBY_INTERPRETER != :mri && library =~ /(typhoeus|curb|patron|em-http)/)

  describe "using #{adapter_module.http_library_name}", :unless => http_lib_unsupported do
    include adapter_module

    # Necessary for ruby 1.9.2.  On 1.9.2 we get an error when we use super,
    # so this gives us another alias we can use for the original method.
    alias make_request make_http_request

    1.upto(2) do |header_count|
      describe "making an HTTP request that responds with #{header_count} Set-Cookie header(s)" do
        define_method :get_set_cookie_header do
          VCR.use_cassette('header_test', :record => :once) do
            get_header 'Set-Cookie', make_http_request(:get, "http://localhost:#{VCR::SinatraApp.port}/set-cookie-headers/#{header_count}")
          end
        end

        it 'returns the same header value when recording and replaying' do
          (recorded_val = get_set_cookie_header).should_not be_nil
          replayed_val = get_set_cookie_header
          replayed_val.should eq(recorded_val)
        end
      end
    end

    def self.test_record_and_playback(description, query)
      describe "a request to a URL #{description}" do
        define_method :get_body do
          VCR.use_cassette('record_and_playback', :record => :once) do
            get_body_string make_http_request(:get, "http://localhost:#{VCR::SinatraApp.port}/record-and-playback?#{query}")
          end
        end

        it "properly records and playsback a request with a URL #{description}" do
          recorded_body = get_body
          played_back_body = get_body
          played_back_body.should eq(recorded_body)
        end
      end
    end

    test_record_and_playback "with spaces encoded as +",           "q=a+b"
    test_record_and_playback "with spaces encoded as %20",         "q=a%20b"
    test_record_and_playback "with a complex escaped query param", "q=#{CGI.escape("A&(! 234k !@ kasdj232\#$ kjw35")}"

    it 'plays back an empty body response exactly as it was recorded (e.g. nil vs empty string)' do
      pending "awaiting an external fix", :if => library_hook_name == :fakeweb do
        get_body = lambda do
          VCR.use_cassette('empty_body', :record => :once) do
            get_body_object make_http_request(:get, "http://localhost:#{VCR::SinatraApp.port}/204")
          end
        end

        recorded = get_body.call
        played_back = get_body.call
        played_back.should eq(recorded)
      end
    end

    describe 'making an HTTP request' do
      let(:status)        { VCR::ResponseStatus.new(200, 'OK') }
      let(:interaction)   { VCR::HTTPInteraction.new(request, response) }
      let(:response_body) { "The response body" }

      before(:each) do
        stub_requests([interaction], [:method, :uri])
      end

      context "when the the stubbed request and response has no headers" do
        let(:request)  { VCR::Request.new(:get, 'http://example.com:80/') }
        let(:response) { VCR::Response.new(status, nil, response_body, '1.1') }

        it 'returns the response for a matching request' do
          get_body_string(make_http_request(:get, 'http://example.com/')).should eq(response_body)
        end
      end

      def self.test_playback(description, url)
        context "when a URL #{description} has been stubbed" do
          let(:request)     { VCR::Request.new(:get, url) }
          let(:response)    { VCR::Response.new(status, nil, response_body, '1.1') }

          it 'returns the expected response for the same request' do
            get_body_string(make_http_request(:get, url)).should eq(response_body)
          end
        end
      end

      test_playback "using https and no explicit port", "https://example.com/foo"
      test_playback "using https and port 443",         "https://example.com:443/foo"
      test_playback "using https and some other port",  "https://example.com:5190/foo"
      test_playback "that has query params",            "http://example.com/search?q=param"
      test_playback "with an encoded ampersand",        "http://example.com:80/search?q=#{CGI.escape("Q&A")}"
    end

    it 'does not query the http interaction list excessively' do
      call_count = 0
      [:has_interaction_matching?, :response_for].each do |method_name|
        orig_meth = VCR.http_interactions.method(method_name)
        VCR.http_interactions.stub(method_name) do |*args|
          call_count += 1
          orig_meth.call(*args)
        end
      end

      VCR.insert_cassette('foo')
      make_http_request(:get, "http://localhost:#{VCR::SinatraApp.port}/foo")

      call_count.should eq(1)
    end

    describe "using the library's stubbing/disconnection APIs" do
      let!(:request_url) { "http://localhost:#{VCR::SinatraApp.port}/foo" }

      if method_defined?(:disable_real_connections)
        it 'can make a real request when VCR is turned off' do
          enable_real_connections
          VCR.turn_off!
          get_body_string(make_http_request(:get, request_url)).should eq("FOO!")
        end

        it 'does not mess with VCR when real connections are disabled' do
          VCR.insert_cassette('example')
          disable_real_connections

          VCR.should_receive(:record_http_interaction) do |interaction|
            interaction.request.uri.should eq(request_url)
          end

          make_http_request(:get, request_url)
        end

        it 'can disable real connections when VCR is turned off' do
          VCR.turn_off!
          expected_error = disable_real_connections

          expect {
            make_http_request(:get, request_url)
          }.to raise_error(expected_error)
        end
      end

      if method_defined?(:directly_stub_request)
        it 'can directly stub the request when VCR is turned off' do
          VCR.turn_off!
          directly_stub_request(:get, request_url, "stubbed response")
          get_body_string(make_http_request(:get, request_url)).should eq("stubbed response")
        end

        it 'can directly stub the request when VCR is turned on and no cassette is in use' do
          directly_stub_request(:get, request_url, "stubbed response")
          get_body_string(make_http_request(:get, request_url)).should eq("stubbed response")
        end

        it 'can directly stub the request when VCR is turned on and a cassette is in use' do
          VCR.use_cassette("temp") do
            directly_stub_request(:get, request_url, "stubbed response")
            get_body_string(make_http_request(:get, request_url)).should eq("stubbed response")
          end
        end

        it 'does not record requests that are directly stubbed' do
          VCR.should respond_to(:record_http_interaction)
          VCR.should_not_receive(:record_http_interaction)

          VCR.use_cassette("temp") do
            directly_stub_request(:get, request_url, "stubbed response")
            get_body_string(make_http_request(:get, request_url)).should eq("stubbed response")
          end
        end
      end
    end

    describe "request hooks" do
      context 'when there is an around_http_request hook' do
        let(:request_url) { "http://localhost:#{VCR::SinatraApp.port}/foo" }

        it 'yields the request to the block' do
          yielded_request = nil
          VCR.configuration.around_http_request do |request|
            yielded_request = request
            request.proceed
          end

          VCR.use_cassette('new_cassette') do
            make_http_request(:get, request_url)
          end

          yielded_request.method.should eq(:get)
          yielded_request.uri.should eq(request_url)
        end

        it 'returns the response from request.proceed' do
          response = nil
          VCR.configuration.around_http_request do |request|
            response = request.proceed
          end

          VCR.use_cassette('new_cassette') do
            make_http_request(:get, request_url)
          end

          response.body.should eq("FOO!")
        end

        it 'can be used to use a cassette for a request' do
          VCR.configuration.around_http_request do |request|
            VCR.use_cassette('new_cassette', &request)
          end

          VCR.should_receive(:record_http_interaction) do
            VCR.current_cassette.name.should eq('new_cassette')
          end

          VCR.current_cassette.should be_nil
          make_http_request(:get, request_url)
          VCR.current_cassette.should be_nil
        end

        it 'nests them inside each other, making the first declared hook the outermost' do
          order = []

          VCR.configure do |c|
            c.ignore_request { |r| true }
            c.around_http_request do |request|
              order << :before_1
              request.proceed
              order << :after_1
            end

            c.around_http_request do |request|
              order << :before_2
              request.proceed
              order << :after_2
            end
          end

          make_http_request(:get, request_url)

          order.should eq([:before_1, :before_2, :after_2, :after_1])
        end

        it 'raises an appropriate error if the hook does not call request.proceed' do
          VCR.configuration.ignore_request { |r| true }
          hook_declaration = "#{__FILE__}:#{__LINE__ + 1}"
          VCR.configuration.around_http_request { |r| }

          expect {
            make_http_request(:get, request_url)
          }.to raise_error { |error|
            error.message.should include('must call #proceed on the yielded request')
            error.message.should include(hook_declaration)
          }
        end

        it 'does not get a dead fiber error when multiple requests are made' do
          VCR.configuration.around_http_request do |request|
            VCR.use_cassette('new_cassette', &request)
          end

          3.times { make_http_request(:get, request_url) }
        end

        it 'allows the hook to be filtered' do
          order = []
          VCR.configure do |c|
            c.ignore_request { |r| true }
            c.around_http_request(lambda { |r| r.uri =~ /foo/}) do |request|
              order << :before_foo
              request.proceed
              order << :after_foo
            end

            c.around_http_request(lambda { |r| r.uri !~ /foo/}) do |request|
              order << :before_not_foo
              request.proceed
              order << :after_not_foo
            end
          end

          make_http_request(:get, request_url)
          order.should eq([:before_foo, :after_foo])
        end

        it 'ensures that both around/before are invoked or neither' do
          order = []
          allow_1, allow_2 = false, true
          VCR.configure do |c|
            c.ignore_request { |r| true }
            c.around_http_request(lambda { |r| allow_1 = !allow_1 }) do |request|
              order << :before_1
              request.proceed
              order << :after_1
            end

            c.around_http_request(lambda { |r| allow_2 = !allow_2 }) do |request|
              order << :before_2
              request.proceed
              order << :after_2
            end
          end

          make_http_request(:get, request_url)
          order.should eq([:before_1, :after_1])
        end
      end if RUBY_VERSION >= '1.9'

      it 'correctly assigns the correct type to both before and after request hooks, even if they are different' do
        before_type = after_type = nil
        VCR.configuration.before_http_request do |request|
          before_type = request.type
          VCR.insert_cassette('example')
        end

        VCR.configuration.after_http_request do |request|
          after_type = request.type
          VCR.eject_cassette
        end

        make_http_request(:get, "http://localhost:#{VCR::SinatraApp.port}/foo")
        before_type.should be(:unhandled)
        after_type.should be(:recordable)
      end

      context "when the request is ignored" do
        before(:each) do
          VCR.configuration.ignore_request { |r| true }
        end

        it_behaves_like "request hooks", library_hook_name, :ignored
      end

      context "when the request is directly stubbed" do
        before(:each) do
          directly_stub_request(:get, request_url, "FOO!")
        end

        it_behaves_like "request hooks", library_hook_name, :externally_stubbed
      end if method_defined?(:directly_stub_request)

      context 'when the request is recorded' do
        let!(:inserted_cassette) { VCR.insert_cassette('new_cassette') }

        it_behaves_like "request hooks", library_hook_name, :recordable do
          let(:string_in_cassette) { 'example.com get response 1 with path=foo' }

          it 'plays back the cassette when a request is made' do
            VCR.eject_cassette
            VCR.configure do |c|
              c.cassette_library_dir = File.join(VCR::SPEC_ROOT, 'fixtures')
              c.before_http_request do |request|
                VCR.insert_cassette('fake_example_responses', :record => :none)
              end
            end
            get_body_string(make_http_request(:get, 'http://example.com/foo')).should eq(string_in_cassette)
          end

          specify 'the after_http_request hook can be used to eject a cassette after the request is recorded' do
            VCR.configuration.after_http_request { |request| VCR.eject_cassette }

            VCR.should_receive(:record_http_interaction) do |interaction|
              VCR.current_cassette.should be(inserted_cassette)
            end

            make_request
            VCR.current_cassette.should be_nil
          end
        end
      end

      context 'when a stubbed response is played back for the request' do
        before(:each) do
          stub_requests([http_interaction(request_url)], [:method, :uri])
        end

        it_behaves_like "request hooks", library_hook_name, :stubbed_by_vcr
      end

      context 'when the request is not allowed' do
        it_behaves_like "request hooks", library_hook_name, :unhandled do
          undef assert_expected_response
          def assert_expected_response(response)
            response.should be_nil
          end

          undef make_request
          def make_request(disabled = false)
            if disabled
              make_http_request(:get, request_url)
            else
              expect { make_http_request(:get, request_url) }.to raise_error(NET_CONNECT_NOT_ALLOWED_ERROR)
            end
          end
        end
      end
    end

    describe '.stub_requests using specific match_attributes' do
      before(:each) { VCR.stub(:real_http_connections_allowed? => false) }
      let(:interactions) { interactions_from('match_requests_on.yml') }

      let(:normalized_interactions) do
        interactions.each do |i|
          i.request.headers = normalize_request_headers(i.request.headers)
        end
        interactions
      end

      def self.matching_on(attribute, valid, invalid, &block)
        describe ":#{attribute}" do
          let(:perform_stubbing) { stub_requests(normalized_interactions, [attribute]) }

          before(:each) { perform_stubbing }
          module_eval(&block)

          valid.each do |val, response|
            it "returns the expected response for a #{val.inspect} request" do
              get_body_string(make_http_request(val)).should eq(response)
            end
          end

          it "raises an error for a request with a different #{attribute}" do
            expect { make_http_request(invalid) }.to raise_error(NET_CONNECT_NOT_ALLOWED_ERROR)
          end
        end
      end

      matching_on :method, { :get => "get method response", :post => "post method response" }, :put do
        def make_http_request(http_method)
          make_request(http_method, 'http://some-wrong-domain.com/', nil, {})
        end
      end

      matching_on :host, { 'example1.com' => 'example1.com host response', 'example2.com' => 'example2.com host response' }, 'example3.com' do
        def make_http_request(host)
          make_request(:get, "http://#{host}/some/wrong/path", nil, {})
        end
      end

      matching_on :path, { '/path1' => 'path1 response', '/path2' => 'path2 response' }, '/path3' do
        def make_http_request(path)
          make_request(:get, "http://some.wrong.domain.com#{path}?p=q", nil, {})
        end
      end

      matching_on :uri, { 'http://example.com/uri1' => 'uri1 response', 'http://example.com/uri2' => 'uri2 response' }, 'http://example.com/uri3' do
        def make_http_request(uri)
          make_request(:get, uri, nil, {})
        end
      end

      matching_on :body, { 'param=val1' => 'val1 body response', 'param=val2' => 'val2 body response' }, 'param=val3' do
        def make_http_request(body)
          make_request(:put, "http://wrong-domain.com/wrong/path", body, {})
        end
      end

      matching_on :headers, {{ 'X-Http-Header1' => 'val1' } => 'val1 header response', { 'X-Http-Header1' => 'val2' } => 'val2 header response' }, { 'X-Http-Header1' => 'val3' } do
        def make_http_request(headers)
          make_request(:get, "http://wrong-domain.com/wrong/path", nil, headers)
        end
      end
    end

    def self.test_real_http_request(http_allowed, *other)
      let(:url) { "http://localhost:#{VCR::SinatraApp.port}/foo" }

      if http_allowed

        it 'allows real http requests' do
          get_body_string(make_http_request(:get, url)).should eq('FOO!')
        end

        describe 'recording new http requests' do
          let(:recorded_interaction) do
            interaction = nil
            VCR.should_receive(:record_http_interaction) { |i| interaction = i }
            make_http_request(:post, url, "the body", { 'X-Http-Foo' => 'bar' })
            interaction
          end

          it 'does not record the request if the hook is disabled' do
            VCR.library_hooks.exclusively_enabled :something_else do
              VCR.should_not_receive(:record_http_interaction)
              make_http_request(:get, url)
            end
          end unless other.include?(:not_disableable)

          it 'records the request uri' do
            recorded_interaction.request.uri.should eq(url)
          end

          it 'records the request method' do
            recorded_interaction.request.method.should eq(:post)
          end

          it 'records the request body' do
            recorded_interaction.request.body.should eq("the body")
          end

          it 'records the request headers' do
            headers = downcase_headers(recorded_interaction.request.headers)
            headers.should include('x-http-foo' => ['bar'])
          end

          it 'records the response status code' do
            recorded_interaction.response.status.code.should eq(200)
          end

          it 'records the response status message' do
            recorded_interaction.response.status.message.strip.should eq('OK')
          end unless other.include?(:status_message_not_exposed)

          it 'records the response body' do
            recorded_interaction.response.body.should eq('FOO!')
          end

          it 'records the response headers' do
            headers = downcase_headers(recorded_interaction.response.headers)
            headers.should include('content-type' => ["text/html;charset=utf-8"])
          end
        end
      else
        it 'does not allow real HTTP requests or record them' do
          VCR.should_receive(:record_http_interaction).never
          expect { make_http_request(:get, url) }.to raise_error(NET_CONNECT_NOT_ALLOWED_ERROR)
        end
      end
    end

    [true, false].each do |http_allowed|
      context "when VCR.real_http_connections_allowed? is returning #{http_allowed}" do
        before(:each) { VCR.stub(:real_http_connections_allowed? => http_allowed) }

        test_real_http_request(http_allowed, *other)

        unless http_allowed
          localhost_response = "Localhost response"

          context 'when ignore_hosts is configured to "127.0.0.1", "localhost"' do
            before(:each) do
              VCR.configure { |c| c.ignore_hosts "127.0.0.1", "localhost" }
            end

            %w[ 127.0.0.1 localhost ].each do |localhost_alias|
              it "allows requests to #{localhost_alias}" do
                get_body_string(make_http_request(:get, "http://#{localhost_alias}:#{VCR::SinatraApp.port}/localhost_test")).should eq(localhost_response)
              end
            end

            it 'does not allow requests to 0.0.0.0' do
              expect { make_http_request(:get, "http://0.0.0.0:#{VCR::SinatraApp.port}/localhost_test") }.to raise_error(NET_CONNECT_NOT_ALLOWED_ERROR)
            end
          end
        end

        context 'when some requests are stubbed' do
          let(:interactions) { interactions_from('fake_example_responses.yml') }
          before(:each) do
            stub_requests(interactions, VCR::RequestMatcherRegistry::DEFAULT_MATCHERS)
          end

          it 'gets the stubbed responses when requests are made to http://example.com/foo, and does not record them' do
            VCR.should_receive(:record_http_interaction).never
            get_body_string(make_http_request(:get, 'http://example.com/foo')).should =~ /example\.com get response \d with path=foo/
          end

          it 'rotates through multiple responses for the same request' do
            get_body_string(make_http_request(:get, 'http://example.com/foo')).should eq('example.com get response 1 with path=foo')
            get_body_string(make_http_request(:get, 'http://example.com/foo')).should eq('example.com get response 2 with path=foo')
          end unless other.include?(:does_not_support_rotating_responses)

          it "correctly handles stubbing multiple values for the same header" do
            header = get_header('Set-Cookie', make_http_request(:get, 'http://example.com/two_set_cookie_headers'))
            header = header.split(', ') if header.respond_to?(:split)
            header.should =~ ['bar=bazz', 'foo=bar']
          end
        end
      end
    end
  end
end
