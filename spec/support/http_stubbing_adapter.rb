share_as :HttpStubbingAdapterStubbed do
  before(:each) { VCR.stub!(:http_stubbing_adapter).and_return(subject) }
end

shared_examples_for "an http stubbing adapter" do
  include HttpStubbingAdapterStubbed
  subject { described_class }

  describe '#request_uri' do
    it 'returns the uri for the given http request' do
      net_http = Net::HTTP.new('example.com', 80)
      request = Net::HTTP::Get.new('/foo/bar')
      subject.request_uri(net_http, request).should == 'http://example.com:80/foo/bar'
    end

    it 'handles basic auth' do
      net_http = Net::HTTP.new('example.com',80)
      request = Net::HTTP::Get.new('/auth.txt')
      request.basic_auth 'user', 'pass'
      subject.request_uri(net_http, request).should == 'http://user:pass@example.com:80/auth.txt'
    end
  end

  describe "#with_http_connections_allowed_set_to" do
    it 'sets http_connections_allowed for the duration of the block to the provided value' do
      [true, false].each do |expected|
        yielded_value = :not_set
        subject.with_http_connections_allowed_set_to(expected) { yielded_value = subject.http_connections_allowed? }
        yielded_value.should == expected
      end
    end

    it 'returns the value returned by the block' do
      subject.with_http_connections_allowed_set_to(true) { :return_value }.should == :return_value
    end

    it 'reverts http_connections_allowed when the block completes' do
      [true, false].each do |expected|
        subject.http_connections_allowed = expected
        subject.with_http_connections_allowed_set_to(true) { }
        subject.http_connections_allowed?.should == expected
      end
    end

    it 'reverts http_connections_allowed when the block completes, even if an error is raised' do
      [true, false].each do |expected|
        subject.http_connections_allowed = expected
        lambda { subject.with_http_connections_allowed_set_to(true) { raise RuntimeError } }.should raise_error(RuntimeError)
        subject.http_connections_allowed?.should == expected
      end
    end
  end
end

shared_examples_for "an http stubbing adapter that supports Net::HTTP" do |*args|
  context "using Net::HTTP" do
    it_should_behave_like 'an http stubbing adapter that supports some HTTP library', *args do
      include NetHTTPAdapter
    end
  end
end

shared_examples_for "an http stubbing adapter that supports some HTTP library" do |*supported_request_match_attributes|
  include HttpStubbingAdapterStubbed
  subject { described_class }

  NET_CONNECT_NOT_ALLOWED_ERROR = [StandardError, /You can use VCR to automatically record this request and replay it later/] unless defined?(NET_CONNECT_NOT_ALLOWED_ERROR)

  describe 'stubbing using specific match_attributes' do
    before(:each) { subject.http_connections_allowed = false }
    let(:interactions) { YAML.load(File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', YAML_SERIALIZATION_VERSION, 'match_requests_on.yml'))) }

    @supported_request_match_attributes = supported_request_match_attributes
    def self.matching_on(attribute, &block)
      supported_request_match_attributes = @supported_request_match_attributes

      describe attribute do
        let(:perform_stubbing) { subject.stub_requests(interactions, [attribute]) }

        if supported_request_match_attributes.include?(attribute)
          before(:each) { perform_stubbing }
          module_eval(&block)
        else
          let(:expected_error) { /does not support matching requests on #{attribute}/ }

          it 'raises an error indicating matching requests on this attribute is not supported' do
            expect { perform_stubbing }.to raise_error(expected_error)
          end

          it 'raises an error from #request_stubbed? indicating matching requests on this attribute is not supported' do
            expect { subject.request_stubbed?(VCR::Request.new, [attribute]) }.to raise_error(expected_error)
          end
        end
      end
    end

    matching_on :method do
      def request(http_method)
        VCR::Request.new(http_method, 'http://some-wrong-domain.com/', nil, {})
      end

      [:get, :post].each do |http_method|
        it "returns the expected response for a :#{http_method}" do
          get_body_string(make_http_request(http_method, 'http://some-wrong-domain.com/')).should == "#{http_method} method response"
        end

        it "returns true from #request_stubbed? for a :#{http_method} request" do
          subject.request_stubbed?(request(http_method), [:method]).should be_true
        end
      end

      it 'raises an error for another method' do
        expect { make_http_request(:put, 'http://some-wrong-domain.com/') }.to raise_error(*NET_CONNECT_NOT_ALLOWED_ERROR)
      end

      it "returns false from #request_stubbed? for another http method"  do
        subject.request_stubbed?(request(:put), [:method]).should be_false
      end
    end

    matching_on :host do
      def request(host)
        VCR::Request.new(:get, "http://#{host}/some/wrong/path", nil, {})
      end

      1.upto(2) do |i|
        it "returns the expected response from example#{i}.com" do
          get_body_string(make_http_request(:get, "http://example#{i}.com/some-wrong-path")).should == "example#{i}.com host response"
        end

        it "returns true from #request_stubbed? for a example#{i}.com request" do
          subject.request_stubbed?(request("example#{i}.com"), [:host]).should be_true
        end
      end

      it 'raises an error for another host' do
        expect { make_http_request(:get, 'http://example3.com/some-wrong-path') }.to raise_error(*NET_CONNECT_NOT_ALLOWED_ERROR)
      end

      it "returns false from #request_stubbed? for a another host" do
        subject.request_stubbed?(request("example3.com"), [:host]).should be_false
      end
    end

    matching_on :uri do
      def request(uri)
        VCR::Request.new(:get, uri, nil, {})
      end

      1.upto(2) do |i|
        it "returns the expected response from example.com/uri#{i}" do
          get_body_string(make_http_request(:get, "http://example.com/uri#{i}")).should == "uri#{i} response"
        end

        it "returns true from #request_stubbed? for a example.com/uri#{i} request" do
          subject.request_stubbed?(request("http://example.com/uri#{i}"), [:uri]).should be_true
        end
      end

      it 'raises an error for another uri' do
        expect { make_http_request(:get, 'http://example.com/uri3') }.to raise_error(*NET_CONNECT_NOT_ALLOWED_ERROR)
      end

      it "returns true from #request_stubbed? for another uri" do
        subject.request_stubbed?(request("http://example.com/uri3"), [:uri]).should be_false
      end
    end

    matching_on :body do
      def request(body)
        VCR::Request.new(:put, "http://wrong-domain.com/wrong/path", body, {})
      end

      1.upto(2) do |i|
        it "returns the expected response for request body 'param=val#{i}'" do
          get_body_string(make_http_request(:put, "http://wrong-domain.com/wrong/path", "param=val#{i}")).should == "val#{i} body response"
        end

        it "returns true from #request_stubbed? for a request with body 'param=val#{i}'" do
          subject.request_stubbed?(request("param=val#{i}"), [:body]).should be_true
        end
      end

      it 'raises an error for another request body' do
        expect {
          res = make_http_request(:put, "http://wrong-domain.com/wrong/path", "param=val3")
        }.to raise_error(*NET_CONNECT_NOT_ALLOWED_ERROR)
      end

      it "returns true from #request_stubbed? for a request with a different body" do
        subject.request_stubbed?(request("param=val3"), [:body]).should be_false
      end
    end

    matching_on :headers do
      def request(headers)
        VCR::Request.new(:get, "http://wrong-domain.com/wrong/path", nil, headers)
      end

      1.upto(2) do |i|
        it "returns the expected response for request header 'X-HTTP-HEADER1 = val#{i}'" do
          get_body_string(make_http_request(:get, "http://wrong-domain.com/wrong/path", {}, 'X-HTTP-HEADER1' => "val#{i}")).should == "val#{i} header response"
        end

        it "returns true from #request_stubbed? for a request with header 'X-HTTP-HEADER1 = val#{i}'" do
          subject.request_stubbed?(request('X-HTTP-HEADER1' => "val#{i}"), [:headers]).should be_true
        end
      end

      it 'raises an error for another request header' do
        expect {
          make_http_request(:get, "http://wrong-domain.com/wrong/path", {}, 'X-HTTP-HEADER1' => "val3")
        }.to raise_error(*NET_CONNECT_NOT_ALLOWED_ERROR)
      end

      it "returns true from #request_stubbed? for a request with a different header" do
        subject.request_stubbed?(request('X-HTTP-HEADER1' => "val3"), [:headers]).should be_false
      end
    end
  end

  def self.test_real_http_request(http_allowed)
    if http_allowed

      it 'allows real http requests' do
        get_body_string(make_http_request(:get, 'http://example.com/foo')).should =~ /The requested URL \/foo was not found/
      end

      it 'records new http requests' do
        VCR.should_receive(:record_http_interaction) do |interaction|
          URI.parse(interaction.request.uri).to_s.should == URI.parse('http://example.com/foo').to_s
          interaction.request.method.should == :get
          interaction.response.status.code.should == 404
          interaction.response.status.message.should == 'Not Found'
          interaction.response.body.should =~ /The requested URL \/foo was not found/
        end

        make_http_request(:get, 'http://example.com/foo')
      end

    else
      it 'does not allow real HTTP requests or record them' do
        VCR.should_receive(:record_http_interaction).never
        lambda { make_http_request(:get, 'http://example.com/foo') }.should raise_error(*NET_CONNECT_NOT_ALLOWED_ERROR)
      end
    end
  end

  def test_request_stubbed(method, url, expected)
    subject.request_stubbed?(VCR::Request.new(method, url), [:method, :uri]).should == expected
  end

  [true, false].each do |http_allowed|
    context "when #http_connections_allowed is set to #{http_allowed}" do
      before(:each) { subject.http_connections_allowed = http_allowed }

      it "returns #{http_allowed} for #http_connections_allowed?" do
        subject.http_connections_allowed?.should == http_allowed
      end

      test_real_http_request(http_allowed)

      unless http_allowed
        describe 'ignore_localhost' do
          let(:localhost_response) { 'A localhost response!' }
          let(:localhost_server)   { VCR::LocalhostServer::STATIC_SERVERS[localhost_response] }

          VCR::LOCALHOST_ALIASES.each do |localhost_alias|
            describe 'when set to true' do
              extend PendingOnHeroku
              before(:each) { subject.ignore_localhost = true }

              it "allows requests to #{localhost_alias}" do
                get_body_string(make_http_request(:get, "http://#{localhost_alias}:#{localhost_server.port}/")).should == localhost_response
              end
            end

            describe 'when set to false' do
              before(:each) { subject.ignore_localhost = false }

              it "does not allow requests to #{localhost_alias}" do
                expect { make_http_request(:get, "http://#{localhost_alias}:#{localhost_server.port}/") }.to raise_error(*NET_CONNECT_NOT_ALLOWED_ERROR)
              end
            end
          end
        end
      end

      context 'when some requests are stubbed, after setting a checkpoint' do
        before(:each) do
          subject.create_stubs_checkpoint(:my_checkpoint)
          @recorded_interactions = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', YAML_SERIALIZATION_VERSION, 'fake_example.com_responses.yml')))
          subject.stub_requests(@recorded_interactions)
        end

        it 'returns true from #request_stubbed? for the requests that are stubbed' do
          test_request_stubbed(:post, 'http://example.com', true)
          test_request_stubbed(:get, 'http://example.com/foo', true)
        end

        it 'returns false from #request_stubbed? for requests that are not stubbed' do
          test_request_stubbed(:post, 'http://example.com/foo', false)
          test_request_stubbed(:get, 'http://google.com', false)
        end

        it 'gets the stubbed responses when multiple post requests are made to http://example.com, and does not record them' do
          VCR.should_receive(:record_http_interaction).never
          get_body_string(make_http_request(:post, 'http://example.com/', { 'id' => '7' })).should == 'example.com post response with id=7'
          get_body_string(make_http_request(:post, 'http://example.com/', { 'id' => '3' })).should == 'example.com post response with id=3'
        end

        it 'gets the stubbed responses when requests are made to http://example.com/foo, and does not record them' do
          VCR.should_receive(:record_http_interaction).never
          get_body_string(make_http_request(:get, 'http://example.com/foo')).should == 'example.com get response with path=foo'
        end

        it "correctly handles stubbing multiple values for the same header" do
          perform_test = lambda do
            get_header('Set-Cookie', make_http_request(:get, 'http://example.com/two_set_cookie_headers')).should =~ ['bar=bazz', 'foo=bar']
          end

          if subject == VCR::HttpStubbingAdapters::FakeWeb
            pending("waiting for my fakeweb fix to be merged into fakeweb and released", &perform_test)
          else
            perform_test.call
          end
        end

        context 'when we restore our previous check point' do
          before(:each) { subject.restore_stubs_checkpoint(:my_checkpoint) }

          test_real_http_request(http_allowed)

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
