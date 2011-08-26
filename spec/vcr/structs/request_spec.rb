require 'spec_helper'

describe VCR::Request do
  describe '#matcher' do
    it 'returns a matcher with the given request' do
      req = VCR::Request.new
      req.matcher([:uri]).request.should eq(req)
    end

    it 'returns a matcher with the given match_attributes' do
      req = VCR::Request.new
      req.matcher([:uri, :headers]).match_attributes.to_a.should =~ [:uri, :headers]
    end
  end

  describe '#method' do
    subject { VCR::Request.new(:get) }

    context 'when given no arguments' do
      it 'returns the HTTP method' do
        subject.method.should eq(:get)
      end
    end

    context 'when given an argument' do
      it 'returns the method object for the named method' do
        m = subject.method(:class)
        m.should be_a(Method)
        m.call.should eq(described_class)
      end
    end
  end

  describe '.from_net_http_request' do
    let(:net_http) { VCR::YAML.load_file("#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/example_net_http.yml") }
    let(:request)  { VCR::YAML.load_file("#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/example_net_http_request.yml") }
    subject { described_class.from_net_http_request(net_http, request) }

    before(:each) do
      VCR.http_stubbing_adapter.should respond_to(:request_uri)
      VCR.http_stubbing_adapter.stub!(:request_uri)
    end

    it            { should be_instance_of(VCR::Request) }
    its(:method)  { should eq(:post) }
    its(:body)    { should eq('id=7') }
    its(:headers) { should eq({ "content-type" => ["application/x-www-form-urlencoded"] }) }

    it 'sets the uri using the http_stubbing_adapter.request_uri' do
      VCR.http_stubbing_adapter.should_receive(:request_uri).with(net_http, request).and_return('foo/bar')
      subject.uri.should eq('foo/bar')
    end
  end

  it_performs 'uri normalization' do
    def instance(uri)
      VCR::Request.new(:get, uri, '', {})
    end
  end

  it_performs 'header normalization' do
    def with_headers(headers)
      described_class.new(:get, 'http://example.com/', nil, headers)
    end
  end

  it_performs 'body normalization' do
    def instance(body)
      described_class.new(:get, 'http://example.com/', body, {})
    end
  end
end
