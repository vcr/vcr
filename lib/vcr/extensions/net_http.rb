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

      vcr_request = VCR::Request.from_net_http_request(self, request)
      response = request_without_vcr(request, body)

      match_attributes = (cass = VCR.current_cassette) ? cass.match_requests_on : VCR::RequestMatcher::DEFAULT_MATCH_ATTRIBUTES
      if started? && !VCR.http_stubbing_adapter.request_stubbed?(vcr_request, match_attributes)
        VCR.record_http_interaction VCR::HTTPInteraction.new(vcr_request, VCR::Response.from_net_http_response(response))
        response.extend VCR::Net::HTTPResponse # "unwind" the response
      end

      yield response if block_given?
      response
    end
  end
end
