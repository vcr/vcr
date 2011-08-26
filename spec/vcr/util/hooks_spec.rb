require 'spec_helper'

describe VCR::Hooks do
  class HooksClass
    include VCR::Hooks
  end

  subject { HooksClass.new }
  let(:invocations) { [] }

  before(:each) do
    subject.instance_eval do
      define_hook :before_foo
      define_hook :before_bar
    end
  end

  describe '#clear_hooks' do
    it 'clears all hooks' do
      subject.before_foo { invocations << :callback }
      subject.clear_hooks
      subject.invoke_hook(:before_foo, nil)
      invocations.should be_empty
    end
  end

  describe '#invoke_hook(:before_foo)' do
    context 'with a tag argument' do
      it 'invokes each of the :before_foo callbacks with a matching tag' do
        subject.before_foo(:green) { invocations << :callback_1 }
        subject.before_foo(:green) { invocations << :callback_2 }

        invocations.should be_empty
        subject.invoke_hook(:before_foo, :green)
        invocations.should eq([:callback_1, :callback_2])
      end

      it 'invokes each of the :before_foo callbacks with no tag' do
        subject.before_foo { invocations << :no_tag_1 }
        subject.before_foo { invocations << :no_tag_2 }

        subject.invoke_hook(:before_foo, :green)
        invocations.should eq([:no_tag_1, :no_tag_2])
      end

      it 'does not invoke any callbacks with a different tag' do
        subject.before_foo(:blue) { invocations << :blue_callback }
        subject.invoke_hook(:before_foo, :green)
        invocations.should be_empty
      end
    end

    context 'without a tag argument' do
      it 'invokes each of the :before_foo callbacks' do
        subject.before_foo { invocations << :callback_1 }
        subject.before_foo { invocations << :callback_2 }

        invocations.should be_empty
        subject.invoke_hook(:before_foo, nil)
        invocations.should eq([:callback_1, :callback_2])
      end

      it 'does not invoke :before_bar callbacks' do
        subject.before_bar { invocations << :bar_callback }
        subject.invoke_hook(:before_foo, nil)
        invocations.should be_empty
      end

      it 'does not invoke any tagged callbacks' do
        subject.before_foo(:blue) { invocations << :blue_callback }
        subject.invoke_hook(:before_foo, nil)
        invocations.should be_empty
      end

      it 'passes along the provided arguments to the callback' do
        subject.before_foo(&lambda { |a, b| invocations << [a, b] })
        subject.invoke_hook(:before_foo, nil, :arg1, :arg2)
        invocations.flatten.should eq([:arg1, :arg2])
      end

      it 'only passes along 1 argument when the block accepts only 1 arguments' do
        subject.before_foo(&lambda { |a| invocations << a })
        subject.invoke_hook(:before_foo, nil, :arg1, :arg2)
        invocations.flatten.should eq([:arg1])
      end

      it 'passes along all arguments when the block accepts a variable number of args' do
        subject.before_foo(&lambda { |*a| invocations << a })
        subject.invoke_hook(:before_foo, nil, :arg1, :arg2)
        invocations.flatten.should eq([:arg1, :arg2])
      end
    end
  end
end

