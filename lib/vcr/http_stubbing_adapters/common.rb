require 'vcr/util/version_checker'

module VCR
  module HttpStubbingAdapters
    autoload :Excon,            'vcr/http_stubbing_adapters/excon'
    autoload :FakeWeb,          'vcr/http_stubbing_adapters/fakeweb'
    autoload :Faraday,          'vcr/http_stubbing_adapters/faraday'
    autoload :MultiObjectProxy, 'vcr/http_stubbing_adapters/multi_object_proxy'
    autoload :Typhoeus,         'vcr/http_stubbing_adapters/typhoeus'
    autoload :WebMock,          'vcr/http_stubbing_adapters/webmock'

    class HttpConnectionNotAllowedError < StandardError; end

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

      def after_adapters_loaded
        # no-op
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
        VersionChecker.new(
          library_name,
          version,
          self::MIN_PATCH_LEVEL,
          self::MAX_MINOR_VERSION
        ).check_version!
      end

      def library_name
        @library_name ||= self.to_s.split('::').last
      end

      def reset!
        instance_variables.each do |ivar|
          remove_instance_variable(ivar)
        end
      end

      def raise_connections_disabled_error(request)
        raise HttpConnectionNotAllowedError.new(
          "Real HTTP connections are disabled. Request: #{request.method.to_s.upcase} #{request.uri}.  " +
          RECORDING_INSTRUCTIONS
        )
      end
    end
  end
end
