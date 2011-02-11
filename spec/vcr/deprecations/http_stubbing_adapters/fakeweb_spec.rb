require 'spec_helper'

describe VCR::HttpStubbingAdapters::FakeWeb, 'deprecations' do
  disable_warnings

  describe 'LOCALHOST_REGEX constant' do
    subject { described_class::LOCALHOST_REGEX }

    it 'refers to the expected regex' do
      should == %r|\Ahttps?://((\w+:)?\w+@)?(#{VCR::LOCALHOST_ALIASES.sort.map { |a| Regexp.escape(a) }.join('|')})(:\d+)?/|i
    end

    it 'prints a warning: WARNING: `VCR::HttpStubbingAdapters::FakeWeb::LOCALHOST_REGEX` is deprecated.' do
      described_class.should_receive(:warn).with("WARNING: `VCR::HttpStubbingAdapters::FakeWeb::LOCALHOST_REGEX` is deprecated.")
      subject
    end
  end
end
