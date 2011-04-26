require 'spec_helper'

shared_examples_for "header normalization" do
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

  it 'ensures header keys are serialized to yaml as raw strings' do
    key = 'my-key'
    key.instance_variable_set(:@foo, 7)
    instance = with_headers(key => ['value1'])
    VCR::YAML.dump(instance.headers).should == VCR::YAML.dump('my-key' => ['value1'])
  end

  it 'ensures header values are serialized to yaml as raw strings' do
    value = 'my-value'
    value.instance_variable_set(:@foo, 7)
    instance = with_headers('my-key' => [value])
    VCR::YAML.dump(instance.headers).should == VCR::YAML.dump('my-key' => ['my-value'])
  end

  it 'handles nested arrays' do
    accept_encoding = [["gzip", "1.0"], ["deflate", "1.0"], ["sdch", "1.0"]]
    instance = with_headers('accept-encoding' => accept_encoding)
    instance.headers['accept-encoding'].should == accept_encoding
  end

  it 'handles nested arrays with floats' do
    accept_encoding = [["gzip", 1.0], ["deflate", 1.0], ["sdch", 1.0]]
    instance = with_headers('accept-encoding' => accept_encoding)
    instance.headers['accept-encoding'].should == accept_encoding
  end
end

shared_examples_for "body normalization" do
  it 'sets empty string to nil' do
    instance('').body.should be_nil
  end

  it "ensures the body is serialized to yaml as a raw string" do
    body = "My String"
    body.instance_variable_set(:@foo, 7)
    VCR::YAML.dump(instance(body).body).should == VCR::YAML.dump("My String")
  end
end

shared_examples_for 'uri normalization' do
  it 'adds port 80 to an http URI that lacks a port' do
    instance('http://example.com/foo').uri.should == 'http://example.com:80/foo'
  end

  it 'keeps the existing port for an http URI' do
    instance('http://example.com:8000/foo').uri.should == 'http://example.com:8000/foo'
  end

  it 'adds port 443 to an https URI that lacks a port' do
    instance('https://example.com/foo').uri.should == 'https://example.com:443/foo'
  end

  it 'keeps the existing port for an https URI' do
    instance('https://example.com:8000/foo').uri.should == 'https://example.com:8000/foo'
  end
end

shared_examples_for 'status message normalization' do
  it 'chomps leading and trailing spaces on the status message' do
    instance(' OK ').message.should == 'OK'
  end

  it 'sets status message to nil when it is the empty string' do
    instance('').message.should be_nil
  end

  it 'sets status message to nil when it is a blank string' do
    instance('  ').message.should be_nil
  end
end
