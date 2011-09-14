require 'net/http'
require 'vcr/extensions/net_http_response'

module Net
  class HTTP
    def request_with_vcr(*args, &block)
      VCR::HttpStubbingAdapters::FakeWeb.on_net_http_request(self, *args, &block)
    end

    alias request_without_vcr request
    alias request request_with_vcr
  end
end
