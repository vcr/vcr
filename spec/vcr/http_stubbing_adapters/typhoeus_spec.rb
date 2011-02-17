require 'spec_helper'

describe VCR::HttpStubbingAdapters::Typhoeus, :without_monkey_patches => :vcr do
  before(:each) do
    ::Typhoeus::Hydra.stubs = []
    ::Typhoeus::Hydra.allow_net_connect = true
  end

  it_behaves_like 'an http stubbing adapter', ['typhoeus'], [:method, :uri, :host, :path, :body, :headers]

  it_performs('version checking',
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
end unless RUBY_PLATFORM == 'java'

