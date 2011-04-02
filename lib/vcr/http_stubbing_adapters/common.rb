module VCR
  module HttpStubbingAdapters
    autoload :Excon,            'vcr/http_stubbing_adapters/excon'
    autoload :FakeWeb,          'vcr/http_stubbing_adapters/fakeweb'
    autoload :Faraday,          'vcr/http_stubbing_adapters/faraday'
    autoload :MultiObjectProxy, 'vcr/http_stubbing_adapters/multi_object_proxy'
    autoload :Typhoeus,         'vcr/http_stubbing_adapters/typhoeus'
    autoload :WebMock,          'vcr/http_stubbing_adapters/webmock'

    class UnsupportedRequestMatchAttributeError < ArgumentError; end

    module Common
      class << self
        attr_accessor :exclusively_enabled_adapter

        def add_vcr_info_to_exception_message(exception_klass)
          exception_klass.class_eval do
            def initialize(message)
              super(message + '.  ' + VCR::HttpStubbingAdapters::Common::RECORDING_INSTRUCTIONS)
            end
          end
        end

        def adapters
          @adapters ||= []
        end

        def included(adapter)
          adapters << adapter
        end
      end

      RECORDING_INSTRUCTIONS = "You can use VCR to automatically record this request and replay it later.  " +
                               "For more details, visit the VCR documentation at: http://relishapp.com/myronmarston/vcr/v/#{VCR.version.gsub('.', '-')}"

      def enabled?
        [nil, self].include? VCR::HttpStubbingAdapters::Common.exclusively_enabled_adapter
      end

      def exclusively_enabled
        VCR::HttpStubbingAdapters::Common.exclusively_enabled_adapter = self

        begin
          yield
        ensure
          VCR::HttpStubbingAdapters::Common.exclusively_enabled_adapter = nil
        end
      end

      def check_version!
        case compare_version
          when :too_low
            raise "You are using #{library_name} #{version}.  VCR requires version #{version_requirement}."
          when :too_high
            warn "You are using #{library_name} #{version}.  VCR is known to work with #{library_name} #{version_requirement}.  It may not work with this version."
        end
      end

      def library_name
        @library_name ||= self.to_s.split('::').last
      end

      def set_http_connections_allowed_to_default
        self.http_connections_allowed = VCR::Config.allow_http_connections_when_no_cassette?
      end

      def restore_stubs_checkpoint(cassette)
        raise ArgumentError.new("No checkpoint for #{cassette.inspect} could be found")
      end

      private

      def compare_version
        major,     minor,     patch     = parse_version(version)
        min_major, min_minor, min_patch = parse_version(self::MINIMUM_VERSION)
        max_major, max_minor            = parse_version(self::MAXIMUM_VERSION)

        case
          when major < min_major; :too_low
          when major > max_major; :too_high
          when minor < min_minor; :too_low
          when minor > max_minor; :too_high
          when patch < min_patch; :too_low
        end
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
