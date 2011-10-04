require 'spec_helper'

describe VCR::Middleware::Faraday do
  %w[ typhoeus net_http patron ].each do |lib|
    it_behaves_like 'a hook into an HTTP library', "faraday (w/ #{lib})",
      :status_message_not_exposed,
      :does_not_support_rotating_responses,
      :not_disableable
  end

  it_performs('version checking', 'Faraday',
    :valid    => %w[ 0.7.0 0.7.10 ],
    :too_low  => %w[ 0.6.9 0.5.99 ],
    :too_high => %w[ 0.8.0 1.0.0 ],
    :file     => 'vcr/middleware/faraday.rb'
  ) do
    before(:each) { @orig_version = Faraday::VERSION }
    after(:each)  { Faraday::VERSION = @orig_version }

    # Cannot be regular method def as that raises a "dynamic constant assignment" error
    define_method :stub_version do |version|
      ::Faraday::VERSION = version
    end
  end
end
