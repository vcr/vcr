require 'spec_helper'

describe VCR::InternetConnection do
  describe '.available?' do
    before(:each) do
      described_class.instance_variable_set(:@available, nil)
    end

    it 'returns true when pinging example.com succeeds' do
      Ping.stub(:pingecho).with("example.com", anything, anything).and_return(true)
      described_class.available?.should be_true
    end

    it 'returns false when pinging example.com fails' do
      Ping.stub(:pingecho).with("example.com", anything, anything).and_return(false)
      described_class.available?.should be_false
    end
  end
end
