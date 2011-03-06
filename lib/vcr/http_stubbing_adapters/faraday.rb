require 'faraday'

module VCR
  module HttpStubbingAdapters
    module Faraday
      include Common
      extend self

      MINIMUM_VERSION = '0.5.3'
      MAXIMUM_VERSION = '0.5'

      attr_writer :http_connections_allowed

      def http_connections_allowed?
        !!@http_connections_allowed
      end

      def ignored_hosts=(hosts)
        @ignored_hosts = hosts
      end

      def uri_should_be_ignored?(uri)
        uri = URI.parse(uri) unless uri.respond_to?(:host)
        ignored_hosts.include?(uri.host)
      end

      def stub_requests(http_interactions, match_attributes)
        grouped_responses(http_interactions, match_attributes).each do |request_matcher, responses|
          matcher = request_matcher_with_normalized_uri(request_matcher)
          queue = stub_queues[matcher]
          responses.each { |res| queue << res }
        end
      end

      def create_stubs_checkpoint(cassette)
        checkpoints[cassette] = stub_queue_dup
      end

      def restore_stubs_checkpoint(cassette)
        @stub_queues = checkpoints.delete(cassette) || super
      end

      def stubbed_response_for(request_matcher)
        queue = stub_queues[request_matcher]
        return queue.shift if queue.size > 1
        queue.first
      end

      def reset!
        instance_variables.each do |ivar|
          remove_instance_variable(ivar)
        end
      end

      private

        def version
          ::Faraday::VERSION
        end

        def ignored_hosts
          @ignored_hosts ||= []
        end

        def checkpoints
          @checkpoints ||= {}
        end

        def stub_queues
          @stub_queues ||= hash_of_arrays
        end

        def stub_queue_dup
          dup = hash_of_arrays

          stub_queues.each do |k, v|
            dup[k] = v.dup
          end

          dup
        end

        def hash_of_arrays
          Hash.new { |h, k| h[k] = [] }
        end

        def request_matcher_with_normalized_uri(matcher)
          return matcher unless matcher.uri.is_a?(String) && matcher.uri.include?('+')

          request = matcher.request.dup
          request.uri = request.uri.gsub('+', '%20')

          RequestMatcher.new(request, matcher.match_attributes)
        end
    end
  end
end

VCR::HttpStubbingAdapters::Common.add_vcr_info_to_exception_message(VCR::Middleware::Faraday::HttpConnectionNotAllowedError)
