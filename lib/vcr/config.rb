require 'fileutils'

module VCR
  class Config
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

      attr_reader :http_stubbing_libraries
      def stub_with(*http_stubbing_libraries)
        @http_stubbing_libraries = http_stubbing_libraries
      end

      def ignore_localhost=(value)
        VCR.http_stubbing_adapter && VCR.http_stubbing_adapter.ignore_localhost = value
        @ignore_localhost = value
      end

      def ignore_localhost?
        VCR.http_stubbing_adapter ? VCR.http_stubbing_adapter.ignore_localhost? : @ignore_localhost
      end
    end
  end
end
