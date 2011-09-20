require 'fakeweb'
require 'net/http'
require 'vcr/extensions/net_http_response'

module VCR
  module HttpStubbingAdapters
    module FakeWeb
      include VCR::HttpStubbingAdapters::Common
      extend self

      MIN_PATCH_LEVEL   = '1.3.0'
      MAX_MINOR_VERSION = '1.3'

    private

      def version
        ::FakeWeb::VERSION
      end

      class RequestHandler
        extend Forwardable

        attr_reader :net_http, :request, :request_body, :block
        def_delegators :"VCR::HttpStubbingAdapters::FakeWeb",
                       :enabled?,
                       :uri_should_be_ignored?,
                       :http_connections_allowed?

        def initialize(net_http, request, request_body = nil, &block)
          @net_http, @request, @request_body, @block =
           net_http,  request,  request_body,  block
        end

        def handle
          if !enabled? || uri_should_be_ignored?(uri)
            perform_request
          elsif stubbed_response
            perform_stubbed_request
          elsif http_connections_allowed?
            perform_and_record_request
          else
            raise_connections_disabled_error
          end
        end

        def perform_and_record_request
          # Net::HTTP calls #request recursively in certain circumstances.
          # We only want to record hte request when the request is started, as
          # that is the final time through #request.
          return perform_request unless net_http.started?

          perform_request do |response|
            VCR.record_http_interaction VCR::HTTPInteraction.new(vcr_request, vcr_response_from(response))
            response.extend VCR::Net::HTTPResponse # "unwind" the response
            block.call(response) if block
          end
        end

        def perform_stubbed_request
          with_exclusive_fakeweb_stub(stubbed_response) do
            perform_request
          end
        end

        def perform_request(&record_block)
          net_http.request_without_vcr(request, request_body, &(record_block || block))
        end

        def raise_connections_disabled_error
          VCR::HttpStubbingAdapters::FakeWeb.raise_connections_disabled_error(vcr_request)
        end

        def uri
          @uri ||= ::FakeWeb::Utility.request_uri_as_string(net_http, request)
        end

        def response_hash(response)
          (response.headers || {}).merge(
            :body   => response.body,
            :status => [response.status.code.to_s, response.status.message]
          )
        end

        def with_exclusive_fakeweb_stub(response)
          original_map = ::FakeWeb::Registry.instance.uri_map.dup
          ::FakeWeb.clean_registry
          ::FakeWeb.register_uri(:any, /.*/, response_hash(response))

          begin
            return yield
          ensure
            ::FakeWeb::Registry.instance.uri_map = original_map
          end
        end

        def stubbed_response
          @stubbed_response ||= VCR.http_interactions.response_for(vcr_request)
        end

        def vcr_request
          @vcr_request ||= VCR::Request.new \
            request.method.downcase.to_sym,
            uri,
            request_body,
            request.to_hash
        end

        def vcr_response_from(response)
          VCR::Response.new \
            VCR::ResponseStatus.new(response.code.to_i, response.message),
            response.to_hash,
            response.body,
            response.http_version
        end
      end
    end
  end
end

module Net
  class HTTP
    def request_with_vcr(*args, &block)
      VCR::HttpStubbingAdapters::FakeWeb::RequestHandler.new(
        self, *args, &block
      ).handle
    end

    alias request_without_vcr request
    alias request request_with_vcr
  end
end
