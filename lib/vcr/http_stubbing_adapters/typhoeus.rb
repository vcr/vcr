require 'typhoeus'

module VCR
  module HttpStubbingAdapters
    module Typhoeus
      include VCR::HttpStubbingAdapters::Common
      extend self

      MINIMUM_VERSION = '0.2.1'
      MAXIMUM_VERSION = '0.2'

      def http_connections_allowed=(value)
        ::Typhoeus::Hydra.allow_net_connect = value
      end

      def http_connections_allowed?
        !!::Typhoeus::Hydra.allow_net_connect?
      end

      def ignored_hosts=(hosts)
        ::Typhoeus::Hydra.ignore_hosts = hosts
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
                :code         => response.status.code,
                :body         => response.body,
                :headers_hash => response.headers
              )
            end
          )
        end
      end

      def create_stubs_checkpoint(cassette)
        checkpoints[cassette] = ::Typhoeus::Hydra.stubs.dup
      end

      def restore_stubs_checkpoint(cassette)
        ::Typhoeus::Hydra.stubs = checkpoints.delete(cassette) || super
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
        hash[:headers] = request_matcher.headers if request_matcher.match_requests_on?(:headers)

        hash
      end
    end
  end
end

Typhoeus::Hydra.after_request_before_on_complete do |request|
  if VCR::HttpStubbingAdapters::Typhoeus.enabled? && !request.response.mock?
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
          request.response.status_message
        ),
        request.response.headers_hash,
        request.response.body,
        request.response.http_version
      )
    )

    VCR.record_http_interaction(http_interaction)
  end
end

module Typhoeus
  class Request
    class << self
      def run_with_cassette(url, params)
        use_cassette = VCR::Config.log_all_to && !VCR::Config.log_all_to.empty?
        VCR.insert_cassette(VCR::Config.log_all_to) if use_cassette
        return_value = run_without_cassette(url, params)
        VCR.eject_cassette if use_cassette
        return_value
      end
      alias_method :run_without_cassette, :run
      alias_method :run, :run_with_cassette
    end
  end 
end

VCR::HttpStubbingAdapters::Common.add_vcr_info_to_exception_message(Typhoeus::Hydra::NetConnectNotAllowedError)

