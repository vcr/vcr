require 'spec_helper'

shared_examples_for "a header normalizer" do
  let(:instance) do
    with_headers('Some_Header' => 'value1', 'aNother' => ['a', 'b'], 'third' => [], 'fourth' => nil)
  end

  it 'normalizes the hash to lower case keys and arrays of values' do
    instance.headers['some_header'].should == ['value1']
    instance.headers['another'].should == ['a', 'b']
  end

  it 'removes empty headers' do
    instance.headers.should_not have_key('third')
    instance.headers.should_not have_key('fourth')
  end

  it 'filters out unimportant default values set by the HTTP library' do
    instance = with_headers('accept' => ['*/*'], 'connection' => 'close', 'http-user' => ['foo'], 'expect' => ['', 'bar'])
    instance.headers.should == { 'http-user' => ['foo'], 'expect' => ['bar'] }
  end

  it 'sets empty hash header to nil' do
    with_headers({}).headers.should be_nil
  end
end

shared_examples_for "a body normalizer" do
  it 'sets empty string to nil' do
    instance('').body.should be_nil
  end

  it "ensures the body is serialized to yaml as a raw string" do
    body = "My String"
    body.instance_variable_set(:@foo, 7)
    instance(body).body.to_yaml.should == "My String".to_yaml
  end
end

describe VCR::Request do
  describe '#matcher' do
    it 'returns a matcher with the given request' do
      req = VCR::Request.new
      req.matcher([:uri]).request.should == req
    end

    it 'returns a matcher with the given match_attributes' do
      req = VCR::Request.new
      req.matcher([:uri, :headers]).match_attributes.to_a.should =~ [:uri, :headers]
    end
  end

  describe 'uri normalization' do
    def request(uri)
      VCR::Request.new(:get, uri, '', {})
    end

    it 'adds port 80 to an http URI that lacks a port' do
      request('http://example.com/foo').uri.should == 'http://example.com:80/foo'
    end

    it 'keeps the existing port for an http URI' do
      request('http://example.com:8000/foo').uri.should == 'http://example.com:8000/foo'
    end

    it 'adds port 443 to an https URI that lacks a port' do
      request('https://example.com/foo').uri.should == 'https://example.com:443/foo'
    end

    it 'keeps the existing port for an https URI' do
      request('https://example.com:8000/foo').uri.should == 'https://example.com:8000/foo'
    end
  end

  describe '.from_net_http_request' do
    let(:net_http) { YAML.load(File.read("#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/example_net_http.yml")) }
    let(:request)  { YAML.load(File.read("#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/example_net_http_request.yml")) }
    subject { described_class.from_net_http_request(net_http, request) }

    before(:each) do
      VCR.http_stubbing_adapter.should respond_to(:request_uri)
      VCR.http_stubbing_adapter.stub!(:request_uri)
    end

    it            { should be_instance_of(VCR::Request) }
    its(:method)  { should == :post  }
    its(:body)    { should == 'id=7'  }
    its(:headers) { should == { "content-type" => ["application/x-www-form-urlencoded"] } }

    it 'sets the uri using the http_stubbing_adapter.request_uri' do
      VCR.http_stubbing_adapter.should_receive(:request_uri).with(net_http, request).and_return('foo/bar')
      subject.uri.should == 'foo/bar'
    end
  end

  it_behaves_like 'a header normalizer' do
    def with_headers(headers)
      described_class.new(:get, 'http://example.com/', nil, headers)
    end
  end

  it_behaves_like 'a body normalizer' do
    def instance(body)
      described_class.new(:get, 'http://example.com/', body, {})
    end
  end
end

describe VCR::ResponseStatus do
  describe '.from_net_http_response' do
    let(:response) { YAML.load(File.read("#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/example_net_http_response.yml")) }
    subject { described_class.from_net_http_response(response) }

    it            { should be_instance_of(described_class) }
    its(:code)    { should == 200 }
    its(:message) { should == 'OK' }
  end

  it 'chomps leading and trailing spaces on the status message' do
    described_class.new(200, ' OK ').message.should == 'OK'
  end

  it 'sets status message to nil when it is the empty string' do
    described_class.new(200, '').message.should be_nil
    described_class.new(200, '  ').message.should be_nil
  end
end

describe VCR::Response do
  describe '.from_net_http_response' do
    let(:response) { YAML.load(File.read("#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/example_net_http_response.yml")) }
    subject { described_class.from_net_http_response(response) }

    it                 { should be_instance_of(described_class) }
    its(:body)         { should == 'The response from example.com' }
    its(:http_version) { should == '1.1' }
    its(:headers)      { should == {
      "last-modified"  => ['Tue, 15 Nov 2005 13:24:10 GMT'],
      "etag"           => ["\"24ec5-1b6-4059a80bfd280\""],
      "content-type"   => ["text/html; charset=UTF-8"],
      "date"           => ['Wed, 31 Mar 2010 02:43:26 GMT'],
      "server"         => ['Apache/2.2.3 (CentOS)'],
      "content-length" => ['438'],
      "accept-ranges"  => ['bytes']
    } }

    it 'assigns the status using VCR::ResponseStatus.from_net_http_response' do
      VCR::ResponseStatus.should respond_to(:from_net_http_response)
      VCR::ResponseStatus.should_receive(:from_net_http_response).with(response).and_return(:the_status)
      subject.status.should == :the_status
    end
  end

  it_behaves_like 'a header normalizer' do
    def with_headers(headers)
      described_class.new(:status, headers, nil, '1.1')
    end
  end

  it_behaves_like 'a body normalizer' do
    def instance(body)
      described_class.new(:status, {}, body, '1.1')
    end
  end
end

describe VCR::HTTPInteraction do
  %w( uri method ).each do |attr|
    it "delegates :#{attr} to the request signature" do
      sig = mock('request signature')
      sig.should_receive(attr).and_return(:the_value)
      instance = described_class.new(sig, nil)
      instance.send(attr).should == :the_value
    end
  end

  describe '#ignored?' do
    it 'returns false by default' do
      should_not be_ignored
    end

    it 'returns true when #ignore! has been called' do
      subject.ignore!
      should be_ignored
    end
  end
end
