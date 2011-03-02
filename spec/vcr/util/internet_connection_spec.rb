require 'spec_helper'

describe VCR::InternetConnection do
  describe '.available?' do
    before(:each) do
      described_class.send(:remove_instance_variable, :@available) if described_class.instance_variable_defined?(:@available)
    end

    def stub_pingecho_with(value)
      VCR::Ping.stub(:pingecho).with("example.com", anything, anything).and_return(value)
    end

    context 'when pinging example.com succeeds' do
      it 'returns true' do
        stub_pingecho_with(true)
        described_class.should be_available
      end

      it 'memoizes the value so no extra pings are made' do
        VCR::Ping.should_receive(:pingecho).once.and_return(true)
        3.times { described_class.available? }
      end
    end

    context 'when pinging example.com fails' do
      it 'returns false' do
        stub_pingecho_with(false)
        described_class.should_not be_available
      end

      it 'memoizes the value so no extra pings are made' do
        VCR::Ping.should_receive(:pingecho).once.and_return(false)
        3.times { described_class.available? }
      end
    end
  end
end
