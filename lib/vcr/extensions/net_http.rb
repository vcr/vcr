require 'net/http'

module Net
  class HTTP
    alias_method :request_without_vcr, :request

    def request(request, body = nil, &block)
      uri = URI.parse(VCR.http_stubbing_adapter.request_uri(self, request))

      if VCR::LOCALHOST_ALIASES.include?(uri.host) && VCR.http_stubbing_adapter.ignore_localhost?
        VCR.http_stubbing_adapter.with_http_connections_allowed_set_to(true) do
          return request_without_vcr(request, body, &block)
        end
      end

      request_headers = request.to_hash # get the request headers before Net::HTTP adds some defaults
      response = request_without_vcr(request, body)

      if started? && !VCR.http_stubbing_adapter.request_stubbed?(request.method.downcase.to_sym, uri)
        VCR.record_http_interaction VCR::HTTPInteraction.from_net_http_objects(self, request, request_headers, response)
        response.extend VCR::Net::HTTPResponse # "unwind" the response
      end

      yield response if block_given?
      response
    end
  end
end
