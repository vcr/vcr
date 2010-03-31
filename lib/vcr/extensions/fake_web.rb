require 'fakeweb'

module FakeWeb
  def self.remove_from_registry(method, url)
    Registry.instance.remove(method, url)
  end

  def self.with_allow_net_connect_set_to(value)
    original_value = FakeWeb.allow_net_connect?
    begin
      FakeWeb.allow_net_connect = value
      yield
    ensure
      FakeWeb.allow_net_connect = original_value
    end
  end

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

  class Registry #:nodoc:
    def remove(method, url)
      uri_map.delete_if do |uri, method_hash|
        if normalize_uri(uri) == normalize_uri(url)
          method_hash.delete(method)
          method_hash.empty? # there's no point in keeping this entry in the uri map if its method hash is empty...
        end
      end
    end
  end
end