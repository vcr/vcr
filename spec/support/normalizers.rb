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
    instance.headers.to_yaml.should == { 'my-key' => ['value1'] }.to_yaml
  end

  it 'ensures header values are serialized to yaml as raw strings' do
    value = 'my-value'
    value.instance_variable_set(:@foo, 7)
    instance = with_headers('my-key' => [value])
    instance.headers.to_yaml.should == { 'my-key' => ['my-value'] }.to_yaml
  end
end

shared_examples_for "body normalization" do
  it 'sets empty string to nil' do
    instance('').body.should be_nil
  end

  it "ensures the body is serialized to yaml as a raw string" do
    body = "My String"
    body.instance_variable_set(:@foo, 7)
    instance(body).body.to_yaml.should == "My String".to_yaml
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
