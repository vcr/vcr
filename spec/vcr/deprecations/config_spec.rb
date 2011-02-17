require 'spec_helper'

describe VCR::Config, 'deprecations', :disable_warnings => true do
  describe '.http_stubbing_library' do
    before(:each) { described_class.stub_with :webmock, :typhoeus }

    it 'returns the first configured stubbing library' do
      described_class.http_stubbing_library.should == :webmock
    end

    it 'prints a warning: WARNING: VCR::Config.http_stubbing_library is deprecated.  Use VCR::Config.http_stubbing_libraries instead' do
      described_class.should_receive(:warn).with("WARNING: `VCR::Config.http_stubbing_library` is deprecated.  Use `VCR::Config.http_stubbing_libraries` instead.")
      described_class.http_stubbing_library
    end
  end

  describe '.http_stubbing_library=' do
    it 'sets http_stubbing_libraries to an array of the given value' do
      described_class.http_stubbing_library = :webmock
      described_class.http_stubbing_libraries.should == [:webmock]
    end

    it 'prints a warning: WARNING: VCR::Config.http_stubbing_library= is deprecated.  Use VCR::Config.stub_with instead' do
      described_class.should_receive(:warn).with("WARNING: `VCR::Config.http_stubbing_library = :webmock` is deprecated.  Use `VCR::Config.stub_with :webmock` instead.")
      described_class.http_stubbing_library = :webmock
    end
  end

  it_behaves_like '.ignore_localhost? deprecation'
end
