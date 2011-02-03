require 'spec_helper'

describe VCR::HTTPInteraction do
  %w( uri method ).each do |attr|
    it "delegates :#{attr} to the request signature" do
      sig = mock('request signature')
      sig.should_receive(attr).and_return(:the_value)
      instance = described_class.new(sig, nil)
      instance.send(attr).should == :the_value
    end
  end

  describe '#ignored?' do
    it 'returns false by default' do
      should_not be_ignored
    end

    it 'returns true when #ignore! has been called' do
      subject.ignore!
      should be_ignored
    end
  end
end
