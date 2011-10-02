require 'spec_helper'

describe VCR::HttpStubbingAdapters::Typhoeus, :with_monkey_patches => :typhoeus do
  it_behaves_like 'an http stubbing adapter', 'typhoeus'

  it_performs('version checking', 'Typhoeus',
    :valid    => %w[ 0.2.1 0.2.99 ],
    :too_low  => %w[ 0.1.0 0.1.31 0.2.0 ],
    :too_high => %w[ 0.3.0 1.0.0 ]
  ) do
    before(:each) { @orig_version = Typhoeus::VERSION }
    after(:each)  { Typhoeus::VERSION = @orig_version }

    # Cannot be regular method def as that raises a "dynamic constant assignment" error
    define_method :stub_version do |version|
      Typhoeus::VERSION = version
    end
  end

  describe "VCR.configuration.after_http_stubbing_adapters_loaded hook", :disable_warnings do
    it 'disables the webmock typhoeus adapter so it does not conflict with our typhoeus adapter' do
      load "vcr/http_stubbing_adapters/typhoeus.rb" # to re-add the hook since it's cleared by each test
      ::WebMock::HttpLibAdapters::TyphoeusAdapter.should_receive(:disable!)
      VCR.configuration.invoke_hook(:after_http_stubbing_adapters_loaded)
    end
  end
end unless RUBY_PLATFORM == 'java'

