require 'forwardable'

module VCR
  class RequestSignature < Struct.new(:method, :uri, :body, :headers)
    def initialize(method, uri, options = {})
      super(method, uri, options[:body], options[:headers])
    end

    def self.from_net_http_request(net_http, request)
      new(
        request.method.downcase.to_sym,
        VCR::Config.http_stubbing_adapter.request_uri(net_http, request),
        { :body => request.body, :headers => request.to_hash }
      )
    end
  end

  class ResponseStatus < Struct.new(:code, :message)
    def self.from_net_http_response(response)
      new(response.code.to_i, response.message)
    end
  end

  class Response < Struct.new(:status, :headers, :body, :http_version)
    def self.from_net_http_response(response)
      new(
        ResponseStatus.from_net_http_response(response),
        headers_from_net_http_response(response),
        response.body,
        response.http_version
      )
    end

    private

    def self.headers_from_net_http_response(response)
      h = {}
      response.each do |k, v|
        h[k] = v
      end
      h
    end
  end

  class HTTPInteraction < Struct.new(:request_signature, :response)
    extend ::Forwardable

    def_delegators :request_signature, :uri, :method

    def self.from_net_http_objects(net_http, request, response)
      new(
        RequestSignature.from_net_http_request(net_http, request),
        Response.from_net_http_response(response)
      )
    end
  end
end
