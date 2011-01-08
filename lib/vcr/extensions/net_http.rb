require 'net/http'
require 'vcr/extensions/net_http_response'

module Net
  class HTTP
    def request_with_vcr(request, body = nil, &block)
      unless VCR::HttpStubbingAdapters::FakeWeb.enabled?
        return request_without_vcr(request, body, &block)
      end

      vcr_request = VCR::Request.from_net_http_request(self, request)
      response = request_without_vcr(request, body)

      match_attributes = if cass = VCR.current_cassette
        cass.match_requests_on
      else
        VCR::RequestMatcher::DEFAULT_MATCH_ATTRIBUTES
      end

      if started? && !VCR.http_stubbing_adapter.request_stubbed?(vcr_request, match_attributes)
        VCR.record_http_interaction VCR::HTTPInteraction.new(vcr_request, VCR::Response.from_net_http_response(response))
        response.extend VCR::Net::HTTPResponse # "unwind" the response
      end

      yield response if block_given?
      response
    end

    alias request_without_vcr request
    alias request request_with_vcr
  end
end
