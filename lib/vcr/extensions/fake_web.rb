require 'fakeweb'

module FakeWeb
  def self.request_uri(net_http, request)
    # Copied from: http://github.com/chrisk/fakeweb/blob/fakeweb-1.2.8/lib/fake_web/ext/net_http.rb#L39-52
    protocol = net_http.use_ssl? ? "https" : "http"

    path = request.path
    path = URI.parse(request.path).request_uri if request.path =~ /^http/

    if request["authorization"] =~ /^Basic /
      userinfo = FakeWeb::Utility.decode_userinfo_from_header(request["authorization"])
      userinfo = FakeWeb::Utility.encode_unsafe_chars_in_userinfo(userinfo) + "@"
    else
      userinfo = ""
    end

    "#{protocol}://#{userinfo}#{net_http.address}:#{net_http.port}#{path}"
  end
end