require 'forwardable'

module VCR
  module HeaderNormalizer
    def initialize(*args)
      super
      normalize_headers
    end

    private

    def normalize_headers
      new_headers = {}

      headers.each do |k, v|
        new_headers[k.downcase] = case v
          when Array then v
          when nil then []
          else [v]
        end
      end if headers

      self.headers = new_headers
    end
  end

  class Request < Struct.new(:method, :uri, :body, :headers)
    include HeaderNormalizer

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
    def self.from_net_http_response(response)
      new(response.code.to_i, response.message)
    end
  end

  class Response < Struct.new(:status, :headers, :body, :http_version)
    include HeaderNormalizer

    def initialize(*args)
      super

      # Ensure that the body is a raw string, in case the string instance
      # has been subclassed or extended with additional instance variables
      # or attributes, so that it is serialized to YAML as a raw string.
      # This is needed for rest-client.  See this ticket for more info:
      # http://github.com/myronmarston/vcr/issues/4
      self.body = String.new(body) if body
    end

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
