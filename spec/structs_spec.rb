require 'spec_helper'

describe VCR::Request do
  describe '.from_net_http_request' do
    let(:net_http) { YAML.load(File.read(File.dirname(__FILE__) + "/fixtures/#{RUBY_VERSION}/example_net_http.yml")) }
    let(:request)  { YAML.load(File.read(File.dirname(__FILE__) + "/fixtures/#{RUBY_VERSION}/example_net_http_request.yml")) }
    subject { described_class.from_net_http_request(net_http, request) }

    before(:each) do
      VCR.http_stubbing_adapter.should respond_to(:request_uri)
      VCR.http_stubbing_adapter.stub!(:request_uri)
    end

    it            { should be_instance_of(VCR::Request) }
    its(:method)  { should == :post  }
    its(:body)    { should == 'id=7'  }
    its(:headers) { should == {
      'accept'       => ['*/*'],
      'content-type' => ['application/x-www-form-urlencoded']
    } }

    it 'sets the uri using the http_stubbing_adapter.request_uri' do
      VCR.http_stubbing_adapter.should_receive(:request_uri).with(net_http, request).and_return('foo/bar')
      subject.uri.should == 'foo/bar'
    end
  end
end

describe VCR::ResponseStatus do
  describe '.from_net_http_response' do
    let(:response) { YAML.load(File.read(File.dirname(__FILE__) + "/fixtures/#{RUBY_VERSION}/example_net_http_response.yml")) }
    subject { described_class.from_net_http_response(response) }

    it            { should be_instance_of(described_class) }
    its(:code)    { should == 200 }
    its(:message) { should == 'OK' }
  end
end

describe VCR::Response do
  describe '.from_net_http_response' do
    let(:response) { YAML.load(File.read(File.dirname(__FILE__) + "/fixtures/#{RUBY_VERSION}/example_net_http_response.yml")) }
    subject { described_class.from_net_http_response(response) }

    it                 { should be_instance_of(described_class) }
    its(:body)         { should == 'The response from example.com' }
    its(:http_version) { should == '1.1' }
    its(:headers)      { should == {
      "last-modified"  => ['Tue, 15 Nov 2005 13:24:10 GMT'],
      "connection"     => ['close'],
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
end

describe VCR::HTTPInteraction do
  describe '.from_net_http_objects' do
    let(:response) { YAML.load(File.read(File.dirname(__FILE__) + "/fixtures/#{RUBY_VERSION}/example_net_http_response.yml")) }
    let(:net_http) { YAML.load(File.read(File.dirname(__FILE__) + "/fixtures/#{RUBY_VERSION}/example_net_http.yml")) }
    let(:request)  { YAML.load(File.read(File.dirname(__FILE__) + "/fixtures/#{RUBY_VERSION}/example_net_http_request.yml")) }
    subject { described_class.from_net_http_objects(net_http, request, response) }

    it 'returns a new record with the proper values' do
      VCR::Request.should respond_to(:from_net_http_request)
      VCR::Request.should_receive(:from_net_http_request).with(net_http, request).and_return(:the_request)

      VCR::Response.should respond_to(:from_net_http_response)
      VCR::Response.should_receive(:from_net_http_response).with(response).and_return(:the_response)

      subject.should be_instance_of(VCR::HTTPInteraction)
      subject.request.should == :the_request
      subject.response.should == :the_response
    end
  end

  %w( uri method ).each do |attr|
    it "delegates :#{attr} to the request signature" do
      sig = mock('request signature')
      sig.should_receive(attr).and_return(:the_value)
      instance = described_class.new(sig, nil)
      instance.send(attr).should == :the_value
    end
  end
end
