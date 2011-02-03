module VCR
  class Request < Struct.new(:method, :uri, :body, :headers)
    include Normalizers::Header
    include Normalizers::URI
    include Normalizers::Body

    def self.from_net_http_request(net_http, request)
      new(
        request.method.downcase.to_sym,
        VCR.http_stubbing_adapter.request_uri(net_http, request),
        request.body,
        request.to_hash
      )
    end

    def matcher(match_attributes)
      RequestMatcher.new(self, match_attributes)
    end
  end
end
