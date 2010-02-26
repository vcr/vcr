require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Net::ReadAdapter extensions' do
  it 'delegates yaml serialization to the body string' do
    adapter = Net::ReadAdapter.new(proc { |s| })
    adapter << 'some text'
    adapter << ' and some more text'
    adapter.to_yaml.should == 'some text and some more text'.to_yaml
  end
end