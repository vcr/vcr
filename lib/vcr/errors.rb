module VCR
  module Errors
    class Error                     < StandardError; end
    class CassetteInUseError        < Error; end
    class TurnedOffError            < Error; end
    class MissingERBVariableError   < Error; end
    class LibraryVersionTooLowError < Error; end
    class UnregisteredMatcherError  < Error; end
    class InvalidCassetteFormatError < Error; end

    class UnhandledHTTPRequestError < Error
      attr_reader :request

      def initialize(request)
        @request = request
        super construct_message
      end
    private

      def construct_message
        "An HTTP request has been made that VCR does not know how to handle:\n" +
        "  #{request.method.to_s.upcase} #{request.uri}"
      end
    end
  end
end

