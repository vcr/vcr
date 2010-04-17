require 'net/http'

module Net
  class HTTP
    def request_with_vcr(request, body = nil, &block)
      @__request_with_vcr_call_count = (@__request_with_vcr_call_count || 0) + 1
      uri = URI.parse(VCR.http_stubbing_adapter.request_uri(self, request))
      if (cassette = VCR.current_cassette) && cassette.allow_real_http_requests_to?(uri)
        VCR.http_stubbing_adapter.with_http_connections_allowed_set_to(true) do
          request_without_vcr(request, body, &block)
        end
      else
        response = request_without_vcr(request, body)
        __store_response_with_vcr__(response, request) if @__request_with_vcr_call_count == 1
        yield response if block_given?
        response
      end
    ensure
      @__request_with_vcr_call_count -= 1
    end
    alias_method :request_without_vcr, :request
    alias_method :request, :request_with_vcr

    private

    def __store_response_with_vcr__(response, request)
      if cassette = VCR.current_cassette
        uri = VCR.http_stubbing_adapter.request_uri(self, request)
        method = request.method.downcase.to_sym

        unless VCR.http_stubbing_adapter.request_stubbed?(method, uri)
          cassette.record_http_interaction(VCR::HTTPInteraction.from_net_http_objects(self, request, response))
        end
      end
    end
  end
end