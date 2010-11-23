shared_examples_for "an http stubbing adapter" do |supported_http_libraries, supported_request_match_attributes, *other|
  extend HttpLibrarySpecs
  before(:each) { VCR.stub!(:http_stubbing_adapter).and_return(subject) }
  subject { described_class }

  describe '.ignore_localhost?' do
    [true, false].each do |val|
      it "returns #{val} when ignore_localhost is set to #{val}" do
        subject.ignore_localhost = val
        subject.ignore_localhost?.should == val
      end
    end

    it "returns false when ignore_localhost is set to nil" do
      subject.ignore_localhost = nil
      subject.ignore_localhost?.should == false
    end
  end

  describe '.set_http_connections_allowed_to_default' do
    [true, false].each do |default|
      context "when VCR::Config.allow_http_connections_when_no_cassette is #{default}" do
        before(:each) { VCR::Config.allow_http_connections_when_no_cassette = default }

        it "sets http_connections_allowed to #{default}" do
          subject.http_connections_allowed = !default
          expect {
            subject.set_http_connections_allowed_to_default
          }.to change { subject.http_connections_allowed? }.from(!default).to(default)
        end
      end
    end
  end

  if other.include?(:needs_net_http_extension)
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

    describe '#request_stubbed? using specific match_attributes' do
      let(:interactions) { YAML.load(File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', YAML_SERIALIZATION_VERSION, 'match_requests_on.yml'))) }

      @supported_request_match_attributes = supported_request_match_attributes
      def self.matching_on(attribute, valid1, valid2, invalid, &block)
        supported_request_match_attributes = @supported_request_match_attributes

        describe ":#{attribute}" do
          if supported_request_match_attributes.include?(attribute)
            before(:each) { subject.stub_requests(interactions, [attribute]) }
            module_eval(&block)

            [valid1, valid2].each do |val|
              it "returns true for a #{val.inspect} request" do
                subject.request_stubbed?(request(val), [attribute]).should == true
              end
            end

            it "returns false for another #{attribute}"  do
              subject.request_stubbed?(request(invalid), [attribute]).should == false
            end
          else
            it 'raises an error indicating matching requests on this attribute is not supported' do
              expect { subject.request_stubbed?(VCR::Request.new, [attribute]) }.to raise_error(/does not support matching requests on #{attribute}/)
            end
          end
        end
      end

      matching_on :method, :get, :post, :put do
        def request(http_method)
          VCR::Request.new(http_method, 'http://some-wrong-domain.com/', nil, {})
        end
      end

      matching_on :host, 'example1.com', 'example2.com', 'example3.com' do
        def request(host)
          VCR::Request.new(:get, "http://#{host}/some/wrong/path", nil, {})
        end
      end

      matching_on :uri, 'http://example.com/uri1', 'http://example.com/uri2', 'http://example.com/uri3' do
        def request(uri)
          VCR::Request.new(:get, uri, nil, {})
        end
      end

      matching_on :path, '/path1', '/path2', '/path3' do
        def request(path)
          VCR::Request.new(:get, "http://example.com#{path}", nil, {})
        end
      end

      matching_on :body, 'param=val1', 'param=val2', 'param=val3' do
        def request(body)
          VCR::Request.new(:put, "http://wrong-domain.com/wrong/path", body, {})
        end
      end

      matching_on :headers, { 'X-HTTP-HEADER1' => 'val1' }, { 'X-HTTP-HEADER1' => 'val2' }, { 'X-HTTP-HEADER1' => 'val3' } do
        def request(headers)
          VCR::Request.new(:get, "http://wrong-domain.com/wrong/path", nil, headers)
        end
      end
    end
  end

  supported_http_libraries.each do |library|
    test_http_library library, supported_request_match_attributes, *other
  end
end

