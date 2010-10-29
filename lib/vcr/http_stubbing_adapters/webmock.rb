require 'webmock'

module VCR
  module HttpStubbingAdapters
    module WebMock
      include VCR::HttpStubbingAdapters::Common
      extend self

      VERSION_REQUIREMENT = '1.4.0'

      def http_connections_allowed?
        ::WebMock::Config.instance.allow_net_connect
      end

      def http_connections_allowed=(value)
        ::WebMock::Config.instance.allow_net_connect = value
      end

      def stub_requests(http_interactions, match_attributes)
        requests = Hash.new { |h,k| h[k] = [] }

        http_interactions.each do |i|
          requests[i.request.matcher(match_attributes)] << i.response
        end

        requests.each do |request_matcher, responses|
          stub = ::WebMock.stub_request(request_matcher.method || :any, request_matcher.uri)

          with_hash = request_signature_hash(request_matcher)
          stub = stub.with(with_hash) if with_hash.size > 0

          stub.to_return(responses.map{ |r| response_hash(r) })
        end
      end

      def create_stubs_checkpoint(checkpoint_name)
        checkpoints[checkpoint_name] = ::WebMock::RequestRegistry.instance.request_stubs.dup
      end

      def restore_stubs_checkpoint(checkpoint_name)
        ::WebMock::RequestRegistry.instance.request_stubs = checkpoints.delete(checkpoint_name)
      end

      def ignore_localhost=(value)
        ::WebMock::Config.instance.allow_localhost = value
      end

      def ignore_localhost?
        ::WebMock::Config.instance.allow_localhost
      end

      private

      def version
        ::WebMock.version
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

VCR::HttpStubbingAdapters::Common.add_vcr_info_to_exception_message(WebMock::NetConnectNotAllowedError)

