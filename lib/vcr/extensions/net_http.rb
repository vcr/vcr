require 'net/http'

module Net
  class HTTP
    def request_with_vcr(request, body = nil, &block)
      uri = URI.parse(VCR.http_stubbing_adapter.request_uri(self, request))

      if %w(localhost 127.0.0.1).include?(uri.host) && VCR.http_stubbing_adapter.ignore_localhost
        VCR.http_stubbing_adapter.with_http_connections_allowed_set_to(true) do
          return request_without_vcr(request, body, &block)
        end
      end

      response = request_without_vcr(request, body)

      if started? && !VCR.http_stubbing_adapter.request_stubbed?(request.method.downcase.to_sym, uri)
        http_interaction = VCR::HTTPInteraction.from_net_http_objects(self, request, response)
        response.extend VCR::Net::HTTPResponse # "unwind" the response

        VCR.record_http_interaction(http_interaction)
      end

      yield response if block_given?
      response
    end
    alias_method :request_without_vcr, :request
    alias_method :request, :request_with_vcr
  end
end
