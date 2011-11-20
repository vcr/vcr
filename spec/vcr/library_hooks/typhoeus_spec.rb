require 'spec_helper'

describe "Typhoeus hook", :with_monkey_patches => :typhoeus do
  it_behaves_like 'a hook into an HTTP library', :typhoeus, 'typhoeus'

  def stub_callback_registration
    # stub the callback registration methods so we don't get a second
    # callback registered when we load the typhoeus file below.
    # Note that we have to use `stub!`, not `stub` because
    # Typhoeus::Hydra defines its own stub method...so to use RSpec's,
    # we use stub!
    ::Typhoeus::Hydra.stub!(:after_request_before_on_complete)
    ::Typhoeus::Hydra.stub!(:register_stub_finder)
  end

  it_performs('version checking', 'Typhoeus',
    :valid    => %w[ 0.3.2 0.3.10 ],
    :too_low  => %w[ 0.2.0 0.2.31 0.3.1 ],
    :too_high => %w[ 0.4.0 1.0.0 ]
  ) do
    before(:each) { @orig_version = Typhoeus::VERSION }
    after(:each)  { Typhoeus::VERSION = @orig_version }

    # Cannot be regular method def as that raises a "dynamic constant assignment" error
    define_method :stub_version do |version|
      Typhoeus::VERSION = version
    end
  end

  describe "VCR.configuration.after_library_hooks_loaded hook", :disable_warnings do
    before(:each) { stub_callback_registration }

    it 'disables the webmock typhoeus adapter so it does not conflict with our typhoeus hook' do
      load "vcr/library_hooks/typhoeus.rb" # to re-add the hook since it's cleared by each test
      ::WebMock::HttpLibAdapters::TyphoeusAdapter.should_receive(:disable!)
      VCR.configuration.invoke_hook(:after_library_hooks_loaded)
    end
  end
end unless RUBY_PLATFORM == 'java'

