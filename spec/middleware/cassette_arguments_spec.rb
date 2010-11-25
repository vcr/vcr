require 'spec_helper'

describe VCR::Middleware::CassetteArguments do
  describe '#name' do
    it 'initially returns nil' do
      subject.name.should be_nil
    end

    it 'stores the given value, returning it when no arg is given' do
      subject.name :value1
      subject.name.should == :value1

      subject.name :value2
      subject.name.should == :value2
    end
  end

  describe '#options' do
    it 'initially returns an empty hash' do
      subject.options.should == {}
    end

    it 'merges the given hash options, returning them when no arg is given' do
      subject.options :record => :new_episodes
      subject.options.should == { :record => :new_episodes }

      subject.options :erb => true
      subject.options.should == { :record => :new_episodes, :erb => true }
    end
  end
end

