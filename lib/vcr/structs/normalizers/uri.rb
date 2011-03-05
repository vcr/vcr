module VCR
  module Normalizers
    module URI
      DEFAULT_PORTS = {
        'http'  => 80,
        'https' => 443
      }

      def initialize(*args)
        super
        normalize_uri
      end

      private

      def normalize_uri
        u = begin
          ::URI.parse(uri)
        rescue ::URI::InvalidURIError
          return
        end

        u.port ||= DEFAULT_PORTS[u.scheme]

        # URI#to_s only includes the port if it's not the default
        # but we want to always include it (since FakeWeb/WebMock
        # urls have always included it).  We force it to be included
        # here by redefining default_port so that URI#to_s will include it.
        def u.default_port; nil; end
        self.uri = VCR.http_stubbing_adapter.normalize_uri(u.to_s)
      end
    end
  end
end
