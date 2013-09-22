require 'spec_helper'

describe VCR::InternetConnection do
  describe '.available?' do
    before(:each) do
      described_class.send(:remove_instance_variable, :@available) if described_class.instance_variable_defined?(:@available)
    end

    def stub_pingecho_with(value)
      allow(VCR::Ping).to receive(:pingecho).with("example.com", anything, anything).and_return(value)
    end

    context 'when pinging example.com succeeds' do
      it 'returns true' do
        stub_pingecho_with(true)
        expect(described_class).to be_available
      end

      it 'memoizes the value so no extra pings are made' do
        expect(VCR::Ping).to receive(:pingecho).once.and_return(true)
        3.times { described_class.available? }
      end
    end

    context 'when pinging example.com fails' do
      it 'returns false' do
        stub_pingecho_with(false)
        expect(described_class).not_to be_available
      end

      it 'memoizes the value so no extra pings are made' do
        expect(VCR::Ping).to receive(:pingecho).once.and_return(false)
        3.times { described_class.available? }
      end
    end
  end
end
