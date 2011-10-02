require 'vcr/util/version_checker'

module VCR
  class HTTPStubbingAdapters
    class HttpConnectionNotAllowedError < StandardError; end

    module Common
      RECORDING_INSTRUCTIONS = "You can use VCR to automatically record this request and replay it later.  " +
                               "For more details, visit the VCR documentation at: http://relishapp.com/myronmarston/vcr/v/#{VCR.version.gsub('.', '-')}"

      def self.raise_connections_disabled_error(request)
        raise HttpConnectionNotAllowedError.new(
          "Real HTTP connections are disabled. Request: #{request.method.to_s.upcase} #{request.uri}.  " +
          RECORDING_INSTRUCTIONS
        )
      end
    end
  end
end
