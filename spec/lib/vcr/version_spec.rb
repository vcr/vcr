require 'spec_helper'

describe "VCR.version" do
  subject { VCR.version }

  it { should =~ /\A\d+\.\d+\.\d+(\.\w+)?\z/ }

  describe '#parts' do
    subject { super().parts }
    it { should be_instance_of(Array)  }
  end

  describe '#major' do
    subject { super().major }
    it { should be_instance_of(Fixnum) }
  end

  describe '#minor' do
    subject { super().minor }
    it { should be_instance_of(Fixnum) }
  end

  describe '#patch' do
    subject { super().patch }
    it { should be_instance_of(Fixnum) }
  end
end
