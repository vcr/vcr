require 'fakeweb'
require 'vcr/extensions/net_http'

module VCR
  module HttpStubbingAdapters
    module FakeWeb
      include VCR::HttpStubbingAdapters::Common
      extend self

      UNSUPPORTED_REQUEST_MATCH_ATTRIBUTES = [:body, :headers]

      MINIMUM_VERSION = '1.3.0'
      MAXIMUM_VERSION = '1.3'

      def http_connections_allowed=(value)
        @http_connections_allowed = value
        update_fakeweb_allow_net_connect
      end

      def http_connections_allowed?
        !!::FakeWeb.allow_net_connect?("http://some.url/besides/localhost")
      end

      def ignored_hosts=(hosts)
        @ignored_hosts = hosts
        update_fakeweb_allow_net_connect
      end

      def stub_requests(http_interactions, match_attributes)
        validate_match_attributes(match_attributes)

        grouped_responses(http_interactions, match_attributes).each do |request_matcher, responses|
          ::FakeWeb.register_uri(
            request_matcher.method || :any,
            request_matcher.uri,
            responses.map{ |r| response_hash(r) }
          )
        end
      end

      def create_stubs_checkpoint(cassette)
        checkpoints[cassette] = ::FakeWeb::Registry.instance.uri_map.dup
      end

      def restore_stubs_checkpoint(cassette)
        ::FakeWeb::Registry.instance.uri_map = checkpoints.delete(cassette) || raise_no_checkpoint_error(cassette)
      end

      def request_stubbed?(request, match_attributes)
        validate_match_attributes(match_attributes)
        !!::FakeWeb.registered_uri?(request.method, request.uri)
      end

      def on_net_http_request(net_http, request, body = nil, &block)
        unless enabled?
          return net_http.request_without_vcr(request, body, &block)
        end

        vcr_request = vcr_request_from(net_http, request)
        response = net_http.request_without_vcr(request, body)

        match_attributes = if cass = VCR.current_cassette
          cass.match_requests_on
        else
          VCR::RequestMatcher::DEFAULT_MATCH_ATTRIBUTES
        end

        if net_http.started? && !request_stubbed?(vcr_request, match_attributes)
          VCR.record_http_interaction VCR::HTTPInteraction.new(vcr_request, vcr_response_from(response))
          response.extend VCR::Net::HTTPResponse # "unwind" the response
        end

        yield response if block_given?
        response
      end

    private

      def ignored_hosts
        @ignored_hosts ||= []
      end

      def version
        ::FakeWeb::VERSION
      end

      def update_fakeweb_allow_net_connect
        ::FakeWeb.allow_net_connect = if @http_connections_allowed
          true
        elsif ignored_hosts.any?
          VCR::Regexes.url_regex_for_hosts(ignored_hosts)
        else
          false
        end
      end

      def checkpoints
        @checkpoints ||= {}
      end

      def response_hash(response)
        (response.headers || {}).merge(
          :body   => response.body,
          :status => [response.status.code.to_s, response.status.message]
        )
      end

      def vcr_request_from(net_http, request)
        VCR::Request.new \
          request.method.downcase.to_sym,
          ::FakeWeb::Utility.request_uri_as_string(net_http, request),
          request.body,
          request.to_hash
      end

      def vcr_response_from(response)
        VCR::Response.new \
          VCR::ResponseStatus.new(response.code.to_i, response.message),
          response.to_hash,
          response.body,
          response.http_version
      end

      def validate_match_attributes(match_attributes)
        invalid_attributes = match_attributes & UNSUPPORTED_REQUEST_MATCH_ATTRIBUTES
        if invalid_attributes.size > 0
          raise UnsupportedRequestMatchAttributeError.new("FakeWeb does not support matching requests on #{invalid_attributes.join(' or ')}")
        end
      end

      def initialize_ivars
        @http_connections_allowed = nil
      end

      initialize_ivars # to avoid warnings
    end
  end
end

VCR::HttpStubbingAdapters::Common.add_vcr_info_to_exception_message(FakeWeb::NetConnectNotAllowedError)

