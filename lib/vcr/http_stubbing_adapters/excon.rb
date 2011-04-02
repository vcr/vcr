require 'excon'

module VCR
  module HttpStubbingAdapters
    module Excon
      include VCR::HttpStubbingAdapters::Common
      extend self

      class HttpConnectionNotAllowedError < StandardError; end

      MINIMUM_VERSION = '0.6.0'
      MAXIMUM_VERSION = '0.6'

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
        match_attributes_stack << match_attributes
        grouped_responses(http_interactions, match_attributes).each do |request_matcher, responses|
          queue = stub_queues[request_matcher]
          responses.each { |res| queue << res }
        end
      end

      def create_stubs_checkpoint(cassette)
        checkpoints[cassette] = stub_queue_dup
      end

      def restore_stubs_checkpoint(cassette)
        match_attributes_stack.pop
        @stub_queues = checkpoints.delete(cassette) || super
      end

      def stubbed_response_for(request)
        return nil unless match_attributes_stack.any?
        request_matcher = request.matcher(match_attributes_stack.last)
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
          ::Excon::VERSION
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

        def match_attributes_stack
          @match_attributes_stack ||= []
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

      class RequestHandler
        attr_reader :params
        def initialize(params)
          @params = params
        end

        def handle
          case
            when request_should_be_ignored?
              perform_real_request
            when stubbed_response
              stubbed_response
            when http_connections_allowed?
              record_interaction
            else
              raise_connections_disabled_error
          end
        end

        private

          def request_should_be_ignored?
            VCR::HttpStubbingAdapters::Excon.uri_should_be_ignored?(uri)
          end

          def stubbed_response
            unless defined?(@stubbed_response)
              @stubbed_response = VCR::HttpStubbingAdapters::Excon.stubbed_response_for(vcr_request)

              if @stubbed_response && @stubbed_response.headers
                @stubbed_response.headers = normalized_headers(@stubbed_response.headers)
              end
            end

            @stubbed_response
          end

          def http_connections_allowed?
            VCR::HttpStubbingAdapters::Excon.http_connections_allowed?
          end

          def perform_real_request
            connection = ::Excon.new(uri)
            response = connection.request(params.merge(:mock => false))

            yield response if block_given?

            {
              :body    => response.body,
              :status  => response.status,
              :headers => response.headers
            }
          end

          def record_interaction
            perform_real_request do |response|
              if VCR::HttpStubbingAdapters::Excon.enabled?
                http_interaction = http_interaction_for(response)
                VCR.record_http_interaction(http_interaction)
              end
            end
          end

          def uri
            @uri ||= begin
              uri = "#{params[:scheme]}://#{params[:host]}:#{params[:port]}#{params[:path]}"
              uri << "?#{params[:query]}" if params[:query]
              uri
            end
          end

          def http_interaction_for(response)
            VCR::HTTPInteraction.new \
              vcr_request,
              vcr_response(response)
          end

          def vcr_request
            @vcr_request ||= begin
              headers = params[:headers].dup
              headers.delete("Host")

              VCR::Request.new \
                params[:method],
                uri,
                params[:body],
                headers
            end
          end

          def vcr_response(response)
            VCR::Response.new \
              VCR::ResponseStatus.new(response.status, nil),
              response.headers,
              response.body,
              nil
          end

          def normalized_headers(headers)
            normalized = {}
            headers.each do |k, v|
              v = v.join(', ') if v.respond_to?(:join)
              normalized[normalize_header_key(k)] = v
            end
            normalized
          end

          def normalize_header_key(key)
            key.split('-').               # 'user-agent' => %w(user agent)
              each { |w| w.capitalize! }. # => %w(User Agent)
              join('-')
          end

          def raise_connections_disabled_error
            raise HttpConnectionNotAllowedError.new(
              "Real HTTP connections are disabled. Request: #{params[:method]} #{uri}"
            )
          end

          ::Excon.stub({}) do |params|
            self.new(params).handle
          end
      end

    end
  end
end

Excon.mock = true
VCR::HttpStubbingAdapters::Common.add_vcr_info_to_exception_message(VCR::HttpStubbingAdapters::Excon::HttpConnectionNotAllowedError)
