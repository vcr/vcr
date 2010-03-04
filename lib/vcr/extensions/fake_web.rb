require 'fake_web'

module FakeWeb
  def self.remove_from_registry(method, url)
    Registry.instance.remove(method, url)
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

  class NetConnectNotAllowedError
    def message
      super + '.  You can use VCR to automatically record this request and replay it later with fakeweb.  For more details, see the VCR README at: http://github.com/myronmarston/vcr'
    end
  end
end