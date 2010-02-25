require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR::Config do
  describe '#cache_dir=' do
    temp_dir(File.expand_path(File.dirname(__FILE__) + '/fixtures/config_spec'))

    it 'creates the directory if it does not exist' do
      lambda { VCR::Config.cache_dir = @temp_dir }.should change { File.exist?(@temp_dir) }.from(false).to(true)
    end

    it 'does not raise an error if given nil' do
      lambda { VCR::Config.cache_dir = nil }.should_not raise_error
    end
  end

  describe '#default_cassette_record_mode' do
    VCR::Cassette::VALID_RECORD_MODES.each do |mode|
      it "allows #{mode}" do
        lambda { VCR::Config.default_cassette_record_mode = mode }.should_not raise_error
      end
    end

    it "does not allow :not_a_record_mode" do
      lambda { VCR::Config.default_cassette_record_mode = :not_a_record_mode }.should raise_error(ArgumentError)
    end
  end
end