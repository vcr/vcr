require 'faraday'

VCR::VersionChecker.new('Faraday', Faraday::VERSION, '0.6.0', '0.6').check_version!

module VCR
  module HttpStubbingAdapters
    module Faraday
      include Common
      extend self
    end
  end
end

