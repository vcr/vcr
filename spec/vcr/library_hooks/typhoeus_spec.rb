require 'spec_helper'

describe "Typhoeus hook", :with_monkey_patches => :typhoeus do
  after(:each) do
    ::Typhoeus::Hydra.clear_stubs
  end

  def disable_real_connections
    ::Typhoeus::Hydra.allow_net_connect = false
    ::Typhoeus::Hydra::NetConnectNotAllowedError
  end

  def enable_real_connections
    ::Typhoeus::Hydra.allow_net_connect = true
  end

  def directly_stub_request(method, url, response_body)
    response = ::Typhoeus::Response.new(:code => 200, :body => response_body)
    ::Typhoeus::Hydra.stub(method, url).and_return(response)
  end

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

  describe "VCR.configuration.after_library_hooks_loaded hook", :disable_warnings do
    before(:each) { stub_callback_registration }

    it 'disables the webmock typhoeus adapter so it does not conflict with our typhoeus hook' do
      load "vcr/library_hooks/typhoeus.rb" # to re-add the hook since it's cleared by each test
      ::WebMock::HttpLibAdapters::TyphoeusAdapter.should_receive(:disable!)
      VCR.configuration.invoke_hook(:after_library_hooks_loaded)
    end
  end
end unless RUBY_PLATFORM == 'java'

