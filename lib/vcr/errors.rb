module VCR
  module Errors
    class Error                     < StandardError; end
    class CassetteInUseError        < Error; end
    class TurnedOffError            < Error; end
    class MissingERBVariableError   < Error; end
    class LibraryVersionTooLowError < Error; end
    class UnregisteredMatcherError  < Error; end
    class InvalidCassetteFormatError < Error; end

    class HTTPConnectionNotAllowedError < Error
      def initialize(request)
        super \
          "Real HTTP connections are disabled. " +
          "Request: #{request.method.to_s.upcase} #{request.uri}. " +
          "You can use VCR to automatically record this request and replay it later. " +
          "For more details, visit the VCR documentation at: http://relishapp.com/myronmarston/vcr/v/#{VCR.version.gsub('.', '-')}"
      end
    end
  end
end

