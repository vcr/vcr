require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR::Config do
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
    it 'returns the configured value' do
      [:fakeweb, :webmock].each do |setting|
        VCR::Config.http_stubbing_adapter = setting
        VCR::Config.http_stubbing_adapter.should == setting
      end
    end

    context 'when set to nil' do
      before(:each) { VCR::Config.http_stubbing_adapter = nil }

      {
        [:FakeWeb, :WebMock] => nil,
        []                   => nil,
        [:FakeWeb]           => :fakeweb,
        [:WebMock]           => :webmock
      }.each do |defined_constants, expected_return_value|
        it "returns #{expected_return_value.inspect} when these constants are defined: #{defined_constants.inspect}" do
          [:FakeWeb, :WebMock].each do |const|
            Object.should_receive(:const_defined?).with(const).and_return(defined_constants.include?(const))
          end
          VCR::Config.http_stubbing_adapter.should == expected_return_value
        end
      end
    end
  end
end