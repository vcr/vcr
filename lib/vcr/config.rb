require 'fileutils'

module VCR
  module Config
    class << self
      attr_reader :cassette_library_dir
      def cassette_library_dir=(cassette_library_dir)
        @cassette_library_dir = cassette_library_dir
        FileUtils.mkdir_p(cassette_library_dir) if cassette_library_dir
      end

      attr_writer :default_cassette_options
      def default_cassette_options
        @default_cassette_options ||= {}
        @default_cassette_options.merge!(:match_requests_on => RequestMatcher::DEFAULT_MATCH_ATTRIBUTES) unless @default_cassette_options.has_key?(:match_requests_on)
        @default_cassette_options
      end

      def stub_with(*http_stubbing_libraries)
        @http_stubbing_libraries = http_stubbing_libraries
      end

      def http_stubbing_libraries
        @http_stubbing_libraries ||= []
      end

      def ignore_localhost=(value)
        @ignore_localhost = value
        VCR.http_stubbing_adapter.ignore_localhost = value if http_stubbing_libraries.any?
      end

      def ignore_localhost?
        @ignore_localhost
      end

      def allow_http_connections_when_no_cassette=(value)
        @allow_http_connections_when_no_cassette = value
        VCR.http_stubbing_adapter.set_http_connections_allowed_to_default if http_stubbing_libraries.any?
      end

      def allow_http_connections_when_no_cassette?
        !!@allow_http_connections_when_no_cassette
      end
    end
  end
end
