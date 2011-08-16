require 'webmock'

module VCR
  module HttpStubbingAdapters
    module WebMock
      include VCR::HttpStubbingAdapters::Common
      extend self

      MINIMUM_VERSION = '1.7.0'
      MAXIMUM_VERSION = '1.7'

      def http_connections_allowed=(value)
        @http_connections_allowed = value
        update_webmock_allow_net_connect
      end

      def http_connections_allowed?
        !!::WebMock::Config.instance.allow_net_connect
      end

      def ignored_hosts=(hosts)
        @ignored_hosts = hosts
        update_webmock_allow_net_connect
      end

      def stub_requests(http_interactions, match_attributes)
        grouped_responses(http_interactions, match_attributes).each do |request_matcher, responses|
          stub = ::WebMock.stub_request(request_matcher.method || :any, request_matcher.uri)

          with_hash = request_signature_hash(request_matcher)
          stub = stub.with(with_hash) if with_hash.size > 0

          stub.to_return(responses.map{ |r| response_hash(r) })
        end
      end

      def create_stubs_checkpoint(cassette)
        checkpoints[cassette] = ::WebMock::StubRegistry.instance.request_stubs.dup
      end

      def restore_stubs_checkpoint(cassette)
        ::WebMock::StubRegistry.instance.request_stubs = checkpoints.delete(cassette) || super
      end

      private

      def version
        ::WebMock.version
      end

      def ignored_hosts
        @ignored_hosts ||= []
      end

      def update_webmock_allow_net_connect
        if @http_connections_allowed
          ::WebMock.allow_net_connect!
        else
          ::WebMock.disable_net_connect!(:allow => ignored_hosts)
        end
      end

      def request_signature_hash(request_matcher)
        signature = {}
        signature[:body]    = request_matcher.body    if request_matcher.match_requests_on?(:body)
        signature[:headers] = request_matcher.headers if request_matcher.match_requests_on?(:headers)
        signature
      end

      def response_hash(response)
        {
          :body    => response.body,
          :status  => [response.status.code.to_i, response.status.message],
          :headers => response.headers
        }
      end

      def checkpoints
        @checkpoints ||= {}
      end
    end
  end
end

WebMock.after_request(:real_requests_only => true) do |request, response|
  if VCR::HttpStubbingAdapters::WebMock.enabled?
    http_interaction = VCR::HTTPInteraction.new(
      VCR::Request.new(
        request.method,
        request.uri.to_s,
        request.body,
        request.headers
      ),
      VCR::Response.new(
        VCR::ResponseStatus.new(
          response.status.first,
          response.status.last
        ),
        response.headers,
        response.body,
        '1.1'
      )
    )

    VCR.record_http_interaction(http_interaction)
  end
end

WebMock::NetConnectNotAllowedError.class_eval do
  def stubbing_instructions(*args)
    '.  ' + VCR::HttpStubbingAdapters::Common::RECORDING_INSTRUCTIONS
  end
end
