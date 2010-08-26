module VCR
  module HttpStubbingAdapters
    autoload :FakeWeb, 'vcr/http_stubbing_adapters/fakeweb'
    autoload :WebMock, 'vcr/http_stubbing_adapters/webmock'

    class UnsupportedRequestMatchAttributeError < ArgumentError; end

    module Common
      def meets_version_requirement?(version, required_version)
        major,     minor,     patch     = *version.split('.').map { |v| v.to_i }
        req_major, req_minor, req_patch = *required_version.split('.').map { |v| v.to_i }

        return false if major < req_major
        return true  if major > req_major

        return false if minor < req_minor
        return true  if minor > req_minor

        patch >= req_patch
      end
    end
  end
end
