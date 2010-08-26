module VCR
  module HttpStubbingAdapters
    autoload :FakeWeb, 'vcr/http_stubbing_adapters/fakeweb'
    autoload :WebMock, 'vcr/http_stubbing_adapters/webmock'

    class UnsupportedRequestMatchAttributeError < ArgumentError; end

    module Common
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
    end
  end
end
