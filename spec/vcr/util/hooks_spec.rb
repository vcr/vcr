require 'spec_helper'

describe VCR::Hooks::FilteredHook do
  describe "#conditionally_invoke" do
    it 'invokes the hook' do
      called = false
      subject.hook = lambda { called = true }
      subject.conditionally_invoke
      expect(called).to be true
    end

    it 'forwards the given arguments to the hook' do
      args = nil
      subject.hook = lambda { |a, b| args = [a, b] }
      subject.conditionally_invoke(3, 5)
      expect(args).to eq([3, 5])
    end

    it 'forwards only as many arguments as the hook block accepts' do
      args = nil
      subject.hook = lambda { |a| args = [a] }
      subject.conditionally_invoke(3, 5)
      expect(args).to eq([3])
    end

    it 'does not invoke the hook if all of the filters return false' do
      called = false
      subject.hook = lambda { called = true }
      subject.filters = lambda { false }
      subject.conditionally_invoke
      expect(called).to be false
    end

    it 'does not invoke the hook if any of the filters returns false' do
      called = false
      subject.hook = lambda { called = true }
      subject.filters = [lambda { false }, lambda { true }]
      subject.conditionally_invoke
      expect(called).to be false
    end

    it 'forwards arguments to the filters' do
      filter_args = nil
      subject.filters = lambda { |a, b| filter_args = [a, b]; false }
      subject.conditionally_invoke(3, 5)
      expect(filter_args).to eq([3, 5])
    end

    it 'handles splat args properly' do
      filter_args = nil
      subject.filters = lambda { |*args| filter_args = args; false }
      subject.conditionally_invoke(3, 5)
      expect(filter_args).to eq([3, 5])
    end

    it 'forwards only as many arguments as the filter blocks accept' do
      args1 = args2 = nil
      subject.filters = [
        lambda { |a| args1 = [a]; true },
        lambda { |a, b| args2 = [a, b]; false }
      ]

      subject.conditionally_invoke(3, 5)
      expect(args1).to eq([3])
      expect(args2).to eq([3, 5])
    end

    it '#to_procs the filter objects' do
      filter_called = false
      subject.hook = lambda { }
      subject.filters = [double(:to_proc => lambda { filter_called = true })]
      subject.conditionally_invoke
      expect(filter_called).to be true
    end
  end
end

describe VCR::Hooks do
  let(:hooks_class) { Class.new { include VCR::Hooks } }

  subject { hooks_class.new }
  let(:invocations) { [] }

  before(:each) do
    hooks_class.instance_eval do
      define_hook :before_foo
      define_hook :before_bar, :prepend
    end
  end

  it 'allows the class to override the hook method and super to the main definition' do
    override_called = nil

    hooks_class.class_eval do
      define_method :before_foo do |&block|
        override_called = true
        super(&block)
      end
    end

    subject.before_foo { }
    expect(override_called).to be true
  end

  describe '#clear_hooks' do
    it 'clears all hooks' do
      subject.before_foo { invocations << :callback }
      subject.clear_hooks
      subject.invoke_hook(:before_foo)
      expect(invocations).to be_empty
    end
  end

  describe '#invoke_hook' do
    it 'invokes each of the callbacks' do
      subject.before_foo { invocations << :callback_1 }
      subject.before_foo { invocations << :callback_2 }

      expect(invocations).to be_empty
      subject.invoke_hook(:before_foo)
      expect(invocations).to eq([:callback_1, :callback_2])
    end

    it 'maps the return value of each callback' do
      subject.before_foo { 17 }
      subject.before_foo { 12 }
      expect(subject.invoke_hook(:before_foo)).to eq([17, 12])
    end

    it 'does not invoke any filtered callbacks' do
      subject.before_foo(:real?) { invocations << :blue_callback }
      subject.invoke_hook(:before_foo, double(:real? => false))
      expect(invocations).to be_empty
    end

    it 'invokes them in reverse order if the hook was defined with :prepend' do
      subject.before_bar { 17 }
      subject.before_bar { 12 }
      expect(subject.invoke_hook(:before_bar)).to eq([12, 17])
    end
  end

  describe "#has_hooks_for?" do
    it 'returns false when given an unrecognized hook name' do
      expect(subject).not_to have_hooks_for(:abcd)
    end

    it 'returns false when given the name of a defined hook that has no registered callbacks' do
      expect(subject).not_to have_hooks_for(:before_foo)
    end

    it 'returns true when given the name of a defined hook that has registered callbacks' do
      subject.before_foo { }
      expect(subject).to have_hooks_for(:before_foo)
    end
  end
end

