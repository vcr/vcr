require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR::Config do
  before(:each) do
    VCR::Config.instance_variable_set('@http_stubbing_adapter', nil)
  end

  describe '#cassette_library_dir=' do
    temp_dir(File.expand_path(File.dirname(__FILE__) + '/fixtures/config_spec'))

    it 'creates the directory if it does not exist' do
      lambda { VCR::Config.cassette_library_dir = @temp_dir }.should change { File.exist?(@temp_dir) }.from(false).to(true)
    end

    it 'does not raise an error if given nil' do
      lambda { VCR::Config.cassette_library_dir = nil }.should_not raise_error
    end
  end

  describe '#default_cassette_options' do
    it 'always has a hash, even if it is set to nil' do
      VCR::Config.default_cassette_options = nil
      VCR::Config.default_cassette_options.should == {}
    end
  end

  describe '#http_stubbing_adapter' do
    it 'returns VCR::HttpStubbingAdapters::FakeWeb when adapter = :fakeweb' do
      VCR::Config.adapter = :fakeweb
      VCR::Config.http_stubbing_adapter.should == VCR::HttpStubbingAdapters::FakeWeb
    end

    it 'raises an error when adapter is not set' do
      VCR::Config.adapter = nil
      lambda { VCR::Config.http_stubbing_adapter }.should raise_error(/The http stubbing adapter is not configured correctly/)
    end
  end
end