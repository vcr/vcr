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
    end
  end
end

