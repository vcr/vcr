require 'vcr/http_stubbing_adapters/common'
require 'faraday'

VCR::VersionChecker.new('Faraday', Faraday::VERSION, '0.6.0', '0.6').check_version!

