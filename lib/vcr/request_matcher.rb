require 'set'

module VCR
  class RequestMatcher
    VALID_MATCH_ATTRIBUTES = [:method, :uri, :host, :path, :headers, :body].freeze
    DEFAULT_MATCH_ATTRIBUTES = [:method, :uri].freeze

    attr_reader :request, :match_attributes

    def initialize(request = nil, match_attributes = [])
      if (match_attributes - VALID_MATCH_ATTRIBUTES).size > 0
        raise ArgumentError.new("The only valid match_attributes options are: #{VALID_MATCH_ATTRIBUTES.inspect}.  You passed: #{match_attributes.inspect}.")
      end

      @request, self.match_attributes = request, match_attributes
    end

    def match_attributes=(attributes)
      @match_attributes = Set.new(attributes)
    end

    def uri
      return request.uri unless request.uri.is_a?(String)
      uri_matchers = match_attributes.to_a & [:uri, :host, :path]

      case Set.new(uri_matchers)
        when Set.new then /.*/
        when Set.new([:uri]) then request.uri
        when Set.new([:host]) then %r{\Ahttps?://((\w+:)?\w+@)?#{Regexp.escape(URI(request.uri).host)}(:\d+)?/}i
        when Set.new([:path]) then %r{\Ahttps?://[^/]+#{Regexp.escape(URI(request.uri).path)}/?(\?.*)?\z}i
        when Set.new([:host, :path])
          uri = URI(request.uri)
          %r{\Ahttps?://((\w+:)?\w+@)?#{Regexp.escape(uri.host)}(:\d+)?#{Regexp.escape(uri.path)}/?(\?.*)?\z}i
        else raise ArgumentError.new("match_attributes cannot include #{uri_matchers.join(' and ')}")
      end
    end

    def method
      request.method if match_requests_on?(:method)
    end

    def headers
      request.headers if match_requests_on?(:headers)
    end

    def body
      request.body if match_requests_on?(:body)
    end

    def match_requests_on?(attribute)
      match_attributes.include?(attribute)
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      %w( class match_attributes method uri headers body ).all? do |attr|
        send(attr) == other.send(attr)
      end
    end

    def hash
      [match_attributes, method, uri, headers, body].hash
    end
  end
end
