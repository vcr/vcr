require 'spec_helper'

describe VCR::HttpStubbingAdapters::Excon do
  it_performs('version checking',
    :valid    => %w[ 0.6.0 0.6.99 ],
    :too_low  => %w[ 0.5.0 ],
    :too_high => %w[ 0.7.0 1.0.0 ]
  ) do
    before(:each) { @orig_version = Excon::VERSION }
    after(:each)  { Excon::VERSION = @orig_version }

    # Cannot be regular method def as that raises a "dynamic constant assignment" error
    define_method :stub_version do |version|
      Excon::VERSION = version
    end
  end
end

