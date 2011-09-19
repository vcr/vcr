require 'faraday'

module VCR
  module HttpStubbingAdapters
    module Faraday
      include Common
      extend self

      MIN_PATCH_LEVEL   = '0.6.0'
      MAX_MINOR_VERSION = '0.6'

      private

      def version
        ::Faraday::VERSION
      end

      def normalize_uri(uri)
        # faraday normalizes +'s to %20's
        uri.gsub('+', '%20')
      end
    end
  end
end

VCR::HttpStubbingAdapters::Common.add_vcr_info_to_exception_message(VCR::Middleware::Faraday::HttpConnectionNotAllowedError)
