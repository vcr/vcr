require 'cgi'

NET_CONNECT_NOT_ALLOWED_ERROR = /You can use VCR to automatically record this request and replay it later/

shared_examples_for "a hook into an HTTP library" do |library, *other|
  include HeaderDowncaser

  def interactions_from(file)
    hashes = YAML.load_file(File.join(VCR::SPEC_ROOT, 'fixtures', file))
    hashes.map { |h| VCR::HTTPInteraction.from_hash(h) }
  end

  unless adapter_module = HTTP_LIBRARY_ADAPTERS[library]
    raise ArgumentError.new("No http library adapter module could be found for #{library}")
  end

  http_lib_unsupported = (RUBY_INTERPRETER != :mri && library =~ /(typhoeus|curb|patron|em-http)/)

  describe "using #{adapter_module.http_library_name}", :unless => http_lib_unsupported do
    include adapter_module

    def stub_requests(*args)
      VCR.stub(:http_interactions => VCR::Cassette::HTTPInteractionList.new(*args))
    end

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

        define_method :should_be_pending do
          if header_count == 2
            [
              'HTTP Client',
              'EM HTTP Request',
              'Curb'
            ].include?(adapter_module.http_library_name)
          end
        end

        it 'returns the same header value when recording and replaying' do
          pending "There appears to be a bug in the the HTTP stubbing library", :if => should_be_pending do
            (recorded_val = get_set_cookie_header).should_not be_nil
            replayed_val = get_set_cookie_header

            # we don't care about order differences if the values are arrays
            if recorded_val.is_a?(Array) && replayed_val.is_a?(Array)
              replayed_val.should =~ recorded_val
            else
              replayed_val.should eq(recorded_val)
            end
          end
        end
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

      def self.test_url(description, url)
        context "when a URL #{description} has been stubbed" do
          let(:request)     { VCR::Request.new(:get, url) }
          let(:response)    { VCR::Response.new(status, nil, response_body, '1.1') }

          it 'returns the expected response for the same request' do
            get_body_string(make_http_request(:get, url)).should eq(response_body)
          end
        end
      end

      test_url "using https and no explicit port", "https://example.com/foo"
      test_url "using https and port 443", "https://example.com:443/foo"
      test_url "using https and some other port", "https://example.com:5190/foo"
      test_url "that has query params",      "http://example.com/search?q=param"
      test_url "with spaces encoded as +",   "http://example.com/search?q=a+b"
      test_url "with spaces encoded as %20", "http://example.com/search?q=a%20b"
      test_url "with an encoded ampersand",  "http://example.com:80/search?q=#{CGI.escape("Q&A")}"
      test_url "with a complex escaped query param", "http://example.com:80/search?q=#{CGI.escape("A&(! 234k !@ kasdj232\#$ kjw35")}"
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
          let(:interactions) { interactions_from('fake_example.com_responses.yml') }
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
