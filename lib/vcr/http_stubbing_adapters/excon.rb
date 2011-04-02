require 'excon'

module VCR
  module HttpStubbingAdapters
    module Excon
      include VCR::HttpStubbingAdapters::Common
      extend self

      MINIMUM_VERSION = '0.6.0'
      MAXIMUM_VERSION = '0.6'

      def http_connections_allowed=(value)
      end

      def http_connections_allowed?
      end

      def ignored_hosts=(hosts)
      end

      def stub_requests(http_interactions, match_attributes)
      end

      def create_stubs_checkpoint(cassette)
      end

      def restore_stubs_checkpoint(cassette)
      end

      private

        def version
        end

        def checkpoints
        end

    end
  end
end
