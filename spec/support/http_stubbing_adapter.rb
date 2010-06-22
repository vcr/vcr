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

shared_examples_for "an http stubbing adapter that supports Net::HTTP" do
  context "using Net::HTTP" do
    def get_body_string(response); response.body; end

    def make_http_request(method, url, body = {})
      case method
        when :get
          Net::HTTP.get_response(URI.parse(url))
        when :post
          Net::HTTP.post_form(URI.parse(url), body)
      end
    end

    it_should_behave_like 'an http stubbing adapter that supports some HTTP library'
  end
end

shared_examples_for "an http stubbing adapter that supports some HTTP library" do
  include HttpStubbingAdapterStubbed
  subject { described_class }

  NET_CONNECT_NOT_ALLOWED_ERROR = [StandardError, /You can use VCR to automatically record this request and replay it later/] unless defined?(NET_CONNECT_NOT_ALLOWED_ERROR)

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
    subject.request_stubbed?(method, url).should == expected
    subject.request_stubbed?(method, URI.parse(url)).should == expected
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
          extend PendingOnHeroku
          let(:localhost_response) { 'A localhost response!' }
          let(:localhost_server)   { VCR::LocalhostServer::STATIC_SERVERS[localhost_response] }

          VCR::LOCALHOST_ALIASES.each do |localhost_alias|
            describe 'when set to true' do
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
          @recorded_interactions = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', RUBY_VERSION, 'fake_example.com_responses.yml')))
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
