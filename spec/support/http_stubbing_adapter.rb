shared_examples_for "an http stubbing adapter" do |supported_http_libraries, supported_request_match_attributes|
  extend HttpLibrarySpecs
  before(:each) { VCR.stub!(:http_stubbing_adapter).and_return(subject) }
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
              subject.request_stubbed?(request(val), [attribute]).should be_true
            end
          end

          it "returns false for another #{attribute}"  do
            subject.request_stubbed?(request(invalid), [attribute]).should be_false
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

  supported_http_libraries.each do |library|
    test_http_library library, supported_request_match_attributes
  end
end

