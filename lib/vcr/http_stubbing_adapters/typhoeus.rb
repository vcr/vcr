require 'typhoeus'

module VCR
  module HttpStubbingAdapters
    module Typhoeus
      include VCR::HttpStubbingAdapters::Common
      extend self

      MINIMUM_VERSION = '0.1.31'
      MAXIMUM_VERSION = '0.1'

      def http_connections_allowed=(value)
        ::Typhoeus::Hydra.allow_net_connect = value
      end

      def http_connections_allowed?
        ::Typhoeus::Hydra.allow_net_connect?
      end

      def ignore_localhost=(value)
        ::Typhoeus::Hydra.ignore_localhost = value
      end

      def ignore_localhost?
        ::Typhoeus::Hydra.ignore_localhost?
      end

      def stub_requests(http_interactions, match_attributes)
        grouped_responses(http_interactions, match_attributes).each do |request_matcher, responses|
          ::Typhoeus::Hydra.stub(
            request_matcher.method || :any,
            request_matcher.uri,
            request_hash(request_matcher)
          ).and_return(
            responses.map do |response|
              ::Typhoeus::Response.new(
                :code    => response.status.code,
                :body    => response.body,
                :headers => response.headers
              )
            end
          )
        end
      end

      def create_stubs_checkpoint(checkpoint_name)
        checkpoints[checkpoint_name] = ::Typhoeus::Hydra.stubs.dup
      end

      def restore_stubs_checkpoint(checkpoint_name)
        ::Typhoeus::Hydra.stubs = checkpoints.delete(checkpoint_name)
      end

      private

      def version
        ::Typhoeus::VERSION
      end

      def checkpoints
        @checkpoints ||= {}
      end

      def request_hash(request_matcher)
        hash = {}

        hash[:body]    = request_matcher.body    if request_matcher.match_requests_on?(:body)

        if request_matcher.match_requests_on?(:headers)
          # normalize the headers to a single value (rather than an array of values)
          # since Typhoeus doesn't yet support multiple header values for a request
          if headers = request_matcher.headers
            headers.each do |k, v|
              headers[k] = v.first
            end
          end

          hash[:headers] = headers
        end

        hash
      end
    end
  end
end

Typhoeus::Hydra.after_request_before_on_complete do |request|
  unless request.response.mock?
    http_interaction = VCR::HTTPInteraction.new(
      VCR::Request.new(
        request.method,
        request.url,
        request.body,
        request.headers
      ),
      VCR::Response.new(
        VCR::ResponseStatus.new(
          request.response.code,
          "TODO" # Typhoeus doesn't expose this yet...
        ),
        request.response.headers,
        request.response.body,
        '1.1' # Typhoeus doesn't expose this...
      )
    )

    VCR.record_http_interaction(http_interaction)
  end
end

VCR::HttpStubbingAdapters::Common.add_vcr_info_to_exception_message(Typhoeus::Hydra::NetConnectNotAllowedError)

