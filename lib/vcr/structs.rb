require 'forwardable'

module VCR
  module BodyNormalizer
    def initialize(*args)
      super
      normalize_body
    end

    private

    def normalize_body
      # Ensure that the body is a raw string, in case the string instance
      # has been subclassed or extended with additional instance variables
      # or attributes, so that it is serialized to YAML as a raw string.
      # This is needed for rest-client.  See this ticket for more info:
      # http://github.com/myronmarston/vcr/issues/4
      self.body = case body
        when nil, ''; nil
        else String.new(body)
      end
    end
  end

  module HeaderNormalizer
    # These headers get added by the various HTTP clients automatically,
    # and we don't care about them.  We store the headers for the purposes
    # of request matching, and we only care to match on headers users
    # explicitly set.
    HEADERS_TO_SKIP = {
      'connection' => %w[ close Keep-Alive ],
      'accept'     => %w[ */* ],
      'expect'     => [''],
      'user-agent' => ["Typhoeus - http://github.com/pauldix/typhoeus/tree/master", 'Ruby']
    }

    def initialize(*args)
      super
      normalize_headers
    end

    private

    def important_header_values(k, values)
      skip_values = HEADERS_TO_SKIP[k] || []
      values - skip_values
    end

    def normalize_headers
      new_headers = {}

      headers.each do |k, v|
        k = k.downcase

        val_array = case v
          when Array then v
          when nil then []
          else [v]
        end

        important_vals = important_header_values(k, val_array)
        next unless important_vals.size > 0

        new_headers[k] = important_vals
      end if headers

      self.headers = new_headers.empty? ? nil : new_headers
    end
  end

  module URINormalizer
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
        URI.parse(uri)
      rescue URI::InvalidURIError
        return
      end

      u.port ||= DEFAULT_PORTS[u.scheme]

      # URI#to_s only includes the port if it's not the default
      # but we want to always include it (since FakeWeb/WebMock
      # urls have always included it).  We force it to be included
      # here by redefining default_port so that URI#to_s will include it.
      def u.default_port; nil; end
      self.uri = u.to_s
    end
  end

  module StatusMessageNormalizer
    def initialize(*args)
      super
      normalize_status_message
    end

    private

    def normalize_status_message
      self.message = message.strip if message
      self.message = nil if message == ''
    end
  end

  class Request < Struct.new(:method, :uri, :body, :headers)
    include HeaderNormalizer
    include URINormalizer
    include BodyNormalizer

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

  class ResponseStatus < Struct.new(:code, :message)
    include StatusMessageNormalizer

    def self.from_net_http_response(response)
      new(response.code.to_i, response.message)
    end
  end

  class Response < Struct.new(:status, :headers, :body, :http_version)
    include HeaderNormalizer
    include BodyNormalizer

    def self.from_net_http_response(response)
      new(
        ResponseStatus.from_net_http_response(response),
        response.to_hash,
        response.body,
        response.http_version
      )
    end
  end

  class HTTPInteraction < Struct.new(:request, :response)
    extend ::Forwardable
    def_delegators :request, :uri, :method
  end
end
