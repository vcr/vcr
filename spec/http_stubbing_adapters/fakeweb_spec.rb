require 'spec_helper'

describe VCR::HttpStubbingAdapters::FakeWeb do
  without_webmock_callbacks

  it_should_behave_like 'an http stubbing adapter', ['net/http'], [:method, :uri, :host, :path]

  describe '#check_version!' do
    disable_warnings
    before(:each) { @orig_version = FakeWeb::VERSION }
    after(:each)  { FakeWeb::VERSION = @orig_version }

    %w( 1.2.8 1.1.30 0.30.30 ).each do |version|
      it "raises an error when FakeWeb's version is #{version}" do
        FakeWeb::VERSION = version
        described_class.should_not_receive(:warn)
        expect { described_class.check_version! }.to raise_error(/You are using FakeWeb #{version}.  VCR requires version .* or greater/)
      end
    end

    %w( 1.3.0 1.3.1 1.3.99 ).each do |version|
      it "does nothing when FakeWeb's version is #{version}" do
        FakeWeb::VERSION = version
        described_class.should_not_receive(:warn)
        expect { described_class.check_version! }.to_not raise_error
      end
    end

    %w( 1.4.0 1.10.0 2.0.0 ).each do |version|
      it "prints a warning when FakeWeb's version is #{version}" do
        FakeWeb::VERSION = version
        described_class.should_receive(:warn).with(/VCR is known to work with FakeWeb ~> .*\./)
        expect { described_class.check_version! }.to_not raise_error
      end
    end
  end
end
