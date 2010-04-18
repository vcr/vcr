require 'set'

module VCR
  class RequestMatcher
    VALID_MATCH_ATTRIBUTES = [:method, :uri, :host, :headers, :body].freeze

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
      matchers = [:uri, :host].select { |m| match_requests_on?(m) }
      raise ArgumentError.new("match_attributes must include only one of :uri and :host, but you have specified #{matchers.inspect}") if matchers.size > 1

      case matchers.first
        when :uri  then request.uri
        when :host then %r{\Ahttps?://#{Regexp.escape(URI.parse(request.uri).host)}}i
        else /.*/
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
      (%w( match_attributes method uri headers body ).map { |attr| send(attr) }).hash
    end
  end
end
