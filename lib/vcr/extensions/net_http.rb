require 'net/http'

module Net
  class HTTP
    def request_with_vcr(request, body = nil, &block)
      @__request_with_vcr_call_count = (@__request_with_vcr_call_count || 0) + 1
      uri = URI.parse(__vcr_uri__(request))
      if (cassette = VCR.current_cassette) && cassette.allow_real_http_requests_to?(uri)
        FakeWeb.with_allow_net_connect_set_to(true) { request_without_vcr(request, body, &block) }
      else
        response = request_without_vcr(request, body, &block)
        __store_response_with_vcr__(response, request) if @__request_with_vcr_call_count == 1
        response
      end
    ensure
      @__request_with_vcr_call_count -= 1
    end
    alias_method :request_without_vcr, :request
    alias_method :request, :request_with_vcr

    private

    def __vcr_uri__(request)
      # Copied from: http://github.com/chrisk/fakeweb/blob/fakeweb-1.2.8/lib/fake_web/ext/net_http.rb#L39-52
      protocol = use_ssl? ? "https" : "http"

      path = request.path
      path = URI.parse(request.path).request_uri if request.path =~ /^http/

      if request["authorization"] =~ /^Basic /
        userinfo = FakeWeb::Utility.decode_userinfo_from_header(request["authorization"])
        userinfo = FakeWeb::Utility.encode_unsafe_chars_in_userinfo(userinfo) + "@"
      else
        userinfo = ""
      end

      "#{protocol}://#{userinfo}#{self.address}:#{self.port}#{path}"
    end

    def __store_response_with_vcr__(response, request)
      if cassette = VCR.current_cassette
        uri = __vcr_uri__(request)
        method = request.method.downcase.to_sym

        unless FakeWeb.registered_uri?(method, uri)
          cassette.store_recorded_response!(VCR::RecordedResponse.new(method, uri, response))
        end
      end
    end
  end
end