module VCR
  module HttpStubbingAdapters
    autoload :FakeWeb, 'vcr/http_stubbing_adapters/fakeweb'
    autoload :WebMock, 'vcr/http_stubbing_adapters/webmock'

    class UnsupportedRequestMatchAttributeError < ArgumentError; end

    module Common
      def self.add_vcr_info_to_exception_message(exception_klass)
        exception_klass.class_eval do
          def message
            super + ".  You can use VCR to automatically record this request and replay it later.  " +
            "For more details, see the VCR README at: http://github.com/myronmarston/vcr/wiki"
          end
        end
      end

      def check_version!
        version_too_low, version_too_high = compare_version

        if version_too_low
          raise "You are using #{library_name} #{version}.  VCR requires version #{self::VERSION_REQUIREMENT} or greater."
        elsif version_too_high
          warn "You are using #{library_name} #{version}.  VCR is known to work with #{library_name} ~> #{self::VERSION_REQUIREMENT}.  It may not work with this version."
        end
      end

      private

      def compare_version
        major,     minor,     patch     = *version.split('.').map { |v| v.to_i }
        req_major, req_minor, req_patch = *self::VERSION_REQUIREMENT.split('.').map { |v| v.to_i }

        return true, false if major < req_major
        return false, true if major > req_major

        return true, false if minor < req_minor
        return false, true if minor > req_minor

        return patch < req_patch, false
      end

      def library_name
        @library_name ||= self.to_s.split('::').last
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
