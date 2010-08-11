require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VCR::HttpStubbingAdapters::FakeWeb do
  it_should_behave_like 'an http stubbing adapter'
  it_should_behave_like 'an http stubbing adapter that supports Net::HTTP', :method, :uri, :host

  describe '#check_version!' do
    disable_warnings
    before(:each) { @orig_version = FakeWeb::VERSION }
    after(:each)  { FakeWeb::VERSION = @orig_version }

    %w( 1.2.8 1.2.9 1.2.10 1.3.0 1.10.0 2.0.0 ).each do |version|
      it "does nothing when FakeWeb's version is #{version}" do
        FakeWeb::VERSION = version
        expect { described_class.check_version! }.to_not raise_error
      end
    end

    %w( 1.2.7 1.1.30 0.30.30 ).each do |version|
      it "raises an error when FakeWeb's version is #{version}" do
        FakeWeb::VERSION = version
        expect { described_class.check_version! }.to raise_error(/You are using FakeWeb #{version}.  VCR requires version .* or greater/)
      end
    end
  end
end
