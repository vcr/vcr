module VCR
  module HttpStubbingAdapters
    autoload :FakeWeb,          'vcr/http_stubbing_adapters/fakeweb'
    autoload :Faraday,          'vcr/http_stubbing_adapters/faraday'
    autoload :MultiObjectProxy, 'vcr/http_stubbing_adapters/multi_object_proxy'
    autoload :Typhoeus,         'vcr/http_stubbing_adapters/typhoeus'
    autoload :WebMock,          'vcr/http_stubbing_adapters/webmock'

    class UnsupportedRequestMatchAttributeError < ArgumentError; end

    module Common
      def self.add_vcr_info_to_exception_message(exception_klass)
        exception_klass.class_eval do
          def initialize(message)
            super(message + '.  ' + VCR::HttpStubbingAdapters::Common::RECORDING_INSTRUCTIONS)
          end
        end
      end

      RECORDING_INSTRUCTIONS = "You can use VCR to automatically record this request and replay it later.  " +
                               "For more details, visit the VCR wiki at: http://github.com/myronmarston/vcr/wiki"

      def check_version!
        version_too_low, version_too_high = compare_version

        if version_too_low
          raise "You are using #{library_name} #{version}.  VCR requires version #{version_requirement}."
        elsif version_too_high
          warn "You are using #{library_name} #{version}.  VCR is known to work with #{library_name} #{version_requirement}.  It may not work with this version."
        end
      end

      def library_name
        @library_name ||= self.to_s.split('::').last
      end

      def set_http_connections_allowed_to_default
        self.http_connections_allowed = VCR::Config.allow_http_connections_when_no_cassette?
      end

      private

      def compare_version
        major,     minor,     patch     = parse_version(version)
        min_major, min_minor, min_patch = parse_version(self::MINIMUM_VERSION)
        max_major, max_minor            = parse_version(self::MAXIMUM_VERSION)

        return true, false if major < min_major
        return false, true if major > max_major

        return true, false if minor < min_minor
        return false, true if minor > max_minor

        return patch < min_patch, false
      end

      def version_requirement
        max_major, max_minor = parse_version(self::MAXIMUM_VERSION)
        ">= #{self::MINIMUM_VERSION}, < #{max_major}.#{max_minor + 1}"
      end

      def parse_version(version)
        version.split('.').map { |v| v.to_i }
      end

      def grouped_responses(http_interactions, match_attributes)
        responses = Hash.new { |h,k| h[k] = [] }

        http_interactions.each do |i|
          responses[i.request.matcher(match_attributes)] << i.response
        end

        responses
      end
    end
  end
end
