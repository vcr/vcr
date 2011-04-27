require 'cgi'

NET_CONNECT_NOT_ALLOWED_ERROR = /You can use VCR to automatically record this request and replay it later/

shared_examples_for "an http library" do |library, supported_request_match_attributes, *other|
  unless adapter_module = HTTP_LIBRARY_ADAPTERS[library]
    raise ArgumentError.new("No http library adapter module could be found for #{library}")
  end

  http_lib_unsupported = if RUBY_INTERPRETER == :mri
    # em-http-request is causing issues on 1.8.6 on travis like:
    # ruby: symbol lookup error: /home/travis/.rvm/gems/ruby-1.8.6-p420/gems/em-http-request-0.3.0/lib/http11_client.so: undefined symbol: rb_hash_lookup
    library =~ /em-http/ && RUBY_VERSION == '1.8.6' && ENV['TRAVIS']
  else
    library =~ /(typhoeus|curb|patron|em-http)/
  end

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
              replayed_val.should == recorded_val
            end
          end
        end
      end
    end

    describe 'making an HTTP request' do
      let(:status)        { VCR::ResponseStatus.new(200, 'OK') }
      let(:interaction)   { VCR::HTTPInteraction.new(request, response) }
      let(:response_body) { "The response body" }
      let(:match_requests_on) { [:method, :uri] }
      let(:record_mode) { :none }

      before(:each) do
        subject.stub_requests([interaction], match_requests_on)
      end

      context "when the the stubbed request and response has no headers" do
        let(:request)  { VCR::Request.new(:get, 'http://example.com:80/') }
        let(:response) { VCR::Response.new(status, nil, response_body, response_body.encoding.to_s, '1.1') }

        it 'returns the response for a matching request' do
          get_body_string(make_http_request(:get, 'http://example.com/')).should == response_body
        end
      end

      def self.test_url(description, url)
        context "when a URL #{description} has been stubbed" do
          let(:request)     { VCR::Request.new(:get, url) }
          let(:response)    { VCR::Response.new(status, nil, response_body, response_body.encoding.to_s, '1.1') }

          it 'returns the expected response for the same request' do
            get_body_string(make_http_request(:get, url)).should == response_body
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
      before(:each) { subject.http_connections_allowed = false }
      let(:interactions) { VCR::YAML.load_file(File.join(VCR::SPEC_ROOT, 'fixtures', YAML_SERIALIZATION_VERSION, 'match_requests_on.yml')) }

      @supported_request_match_attributes = supported_request_match_attributes
      def self.matching_on(attribute, valid, invalid, &block)
        supported_request_match_attributes = @supported_request_match_attributes

        describe ":#{attribute}" do
          let(:perform_stubbing) { subject.stub_requests(interactions, match_requests_on) }
          let(:match_requests_on) { [attribute] }
          let(:record_mode) { :none }

          if supported_request_match_attributes.include?(attribute)
            before(:each) { perform_stubbing }
            module_eval(&block)

            valid.each do |val, response|
              it "returns the expected response for a #{val.inspect} request" do
                get_body_string(make_http_request(val)).should == response
              end
            end

            it "raises an error for a request with a different #{attribute}" do
              expect { make_http_request(invalid) }.to raise_error(NET_CONNECT_NOT_ALLOWED_ERROR)
            end
          else
            it 'raises an error indicating matching requests on this attribute is not supported' do
              expect { perform_stubbing }.to raise_error(/does not support matching requests on #{attribute}/)
            end
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

      matching_on :headers, {{ 'X-HTTP-HEADER1' => 'val1' } => 'val1 header response', { 'X-HTTP-HEADER1' => 'val2' } => 'val2 header response' }, { 'X-HTTP-HEADER1' => 'val3' } do
        def make_http_request(headers)
          make_request(:get, "http://wrong-domain.com/wrong/path", nil, headers)
        end
      end
    end

    def self.test_real_http_request(http_allowed, *other)
      let(:url) { "http://localhost:#{VCR::SinatraApp.port}/foo" }

      if http_allowed

        it 'allows real http requests' do
          get_body_string(make_http_request(:get, url)).should == 'FOO!'
        end

        describe 'recording new http requests' do
          let(:recorded_interaction) do
            interaction = nil
            VCR.should_receive(:record_http_interaction) { |i| interaction = i }
            make_http_request(:get, url)
            interaction
          end

          it 'does not record the request if the adapter is disabled' do
            subject.stub(:enabled?).and_return(false)
            VCR.should_not_receive(:record_http_interaction)
            make_http_request(:get, url)
          end

          it 'records the request uri' do
            recorded_interaction.request.uri.should == url
          end

          it 'records the request method' do
            recorded_interaction.request.method.should == :get
          end

          it 'records the request body' do
            recorded_interaction.request.body.should be_nil
          end

          it 'records the request headers' do
            recorded_interaction.request.headers.should be_nil
          end

          it 'records the response status code' do
            recorded_interaction.response.status.code.should == 200
          end

          it 'records the response status message' do
            recorded_interaction.response.status.message.should == 'OK'
          end unless other.include?(:status_message_not_exposed)

          it 'records the response body' do
            recorded_interaction.response.body.should == 'FOO!'
          end

          it 'records the response headers' do
            recorded_interaction.response.headers['content-type'].should == ["text/html;charset=utf-8"]
          end
        end
      else
        let(:record_mode) { :none }

        it 'does not allow real HTTP requests or record them' do
          VCR.should_receive(:record_http_interaction).never
          expect { make_http_request(:get, url) }.to raise_error(NET_CONNECT_NOT_ALLOWED_ERROR)
        end
      end
    end

    def test_request_stubbed(method, url, expected)
      subject.request_stubbed?(VCR::Request.new(method, url), [:method, :uri]).should == expected
    end

    it "returns false from #http_connections_allowed? when http_connections_allowed is set to nil" do
      subject.http_connections_allowed = nil
      subject.http_connections_allowed?.should == false
    end

    describe '.restore_stubs_checkpoint' do
      it 'raises an appropriate error when there is no matching checkpoint' do
        expect {
          subject.restore_stubs_checkpoint(:some_crazy_checkpoint_that_doesnt_exist)
        }.to raise_error(ArgumentError, /no checkpoint .* could be found/i)
      end
    end

    [true, false].each do |http_allowed|
      context "when http_connections_allowed is set to #{http_allowed}" do
        before(:each) { subject.http_connections_allowed = http_allowed }

        it "returns #{http_allowed} for #http_connections_allowed?" do
          subject.http_connections_allowed?.should == http_allowed
        end

        test_real_http_request(http_allowed, *other)

        unless http_allowed
          localhost_response = "Localhost response"

          describe '.ignore_hosts' do
            let(:record_mode) { :none }

            context 'when set to ["127.0.0.1", "localhost"]' do
              before(:each) do
                subject.ignored_hosts = ["127.0.0.1", "localhost"]
              end

              %w[ 127.0.0.1 localhost ].each do |localhost_alias|
                it "allows requests to #{localhost_alias}" do
                  get_body_string(make_http_request(:get, "http://#{localhost_alias}:#{VCR::SinatraApp.port}/localhost_test")).should == localhost_response
                end
              end

              it 'does not allow requests to 0.0.0.0' do
                expect { make_http_request(:get, "http://0.0.0.0:#{VCR::SinatraApp.port}/localhost_test") }.to raise_error(NET_CONNECT_NOT_ALLOWED_ERROR)
              end
            end
          end
        end

        context 'when some requests are stubbed, after setting a checkpoint' do
          before(:each) do
            subject.create_stubs_checkpoint(:my_checkpoint)
            @recorded_interactions = VCR::YAML.load_file(File.join(VCR::SPEC_ROOT, 'fixtures', YAML_SERIALIZATION_VERSION, 'fake_example.com_responses.yml'))
            subject.stub_requests(@recorded_interactions, VCR::RequestMatcher::DEFAULT_MATCH_ATTRIBUTES)
          end

          if other.include?(:needs_net_http_extension)
            it 'returns true from #request_stubbed? for the requests that are stubbed' do
              test_request_stubbed(:post, 'http://example.com', true)
              test_request_stubbed(:get, 'http://example.com/foo', true)
            end

            it 'returns false from #request_stubbed? for requests that are not stubbed' do
              test_request_stubbed(:post, 'http://example.com/foo', false)
              test_request_stubbed(:get, 'http://google.com', false)
            end
          end

          it 'gets the stubbed responses when requests are made to http://example.com/foo, and does not record them' do
            VCR.should_receive(:record_http_interaction).never
            get_body_string(make_http_request(:get, 'http://example.com/foo')).should =~ /example\.com get response \d with path=foo/
          end

          it 'rotates through multiple responses for the same request' do
            get_body_string(make_http_request(:get, 'http://example.com/foo')).should == 'example.com get response 1 with path=foo'
            get_body_string(make_http_request(:get, 'http://example.com/foo')).should == 'example.com get response 2 with path=foo'

            # subsequent requests keep getting the last one
            get_body_string(make_http_request(:get, 'http://example.com/foo')).should == 'example.com get response 2 with path=foo'
            get_body_string(make_http_request(:get, 'http://example.com/foo')).should == 'example.com get response 2 with path=foo'
          end unless other.include?(:does_not_support_rotating_responses)

          it "correctly handles stubbing multiple values for the same header" do
            header = get_header('Set-Cookie', make_http_request(:get, 'http://example.com/two_set_cookie_headers'))
            header = header.split(', ') if header.respond_to?(:split)
            header.should =~ ['bar=bazz', 'foo=bar']
          end

          context 'when we restore our previous check point' do
            before(:each) { subject.restore_stubs_checkpoint(:my_checkpoint) }

            test_real_http_request(http_allowed, *other)

            if other.include?(:needs_net_http_extension)
              it 'returns false from #request_stubbed?' do
                test_request_stubbed(:get, 'http://example.com/foo', false)
                test_request_stubbed(:post, 'http://example.com', false)
                test_request_stubbed(:get, 'http://google.com', false)
              end
            end
          end
        end
      end
    end
  end
end
