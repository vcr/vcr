require 'spec_helper'

describe VCR::HttpStubbingAdapters::FakeWeb, :with_monkey_patches => :fakeweb do
  it_behaves_like 'an http stubbing adapter', ['net/http'], [:method, :uri, :host, :path], :needs_net_http_extension

  it_performs('version checking',
    :valid    => %w[ 1.3.0 1.3.1 1.3.99 ],
    :too_low  => %w[ 1.2.8 1.1.30 0.30.30 ],
    :too_high => %w[ 1.4.0 1.10.0 2.0.0 ]
  ) do
    before(:each) { @orig_version = FakeWeb::VERSION }
    after(:each)  { FakeWeb::VERSION = @orig_version }

    # Cannot be regular method def as that raises a "dynamic constant assignment" error
    define_method :stub_version do |version|
      FakeWeb::VERSION = version
    end
  end
end
