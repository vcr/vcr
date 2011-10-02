require 'fileutils'
require 'vcr/util/hooks'

module VCR
  class Configuration
    include VCR::Hooks
    include VCR::VariableArgsBlockCaller

    define_hook :before_record
    define_hook :before_playback

    def initialize
      @allow_http_connections_when_no_cassette = nil
    end

    attr_reader :cassette_library_dir
    def cassette_library_dir=(cassette_library_dir)
      @cassette_library_dir = cassette_library_dir
      FileUtils.mkdir_p(cassette_library_dir) if cassette_library_dir
    end

    attr_writer :default_cassette_options
    def default_cassette_options
      @default_cassette_options ||= {}
      @default_cassette_options[:match_requests_on] ||= RequestMatcherRegistry::DEFAULT_MATCHERS
      @default_cassette_options[:record] ||= :once
      @default_cassette_options
    end

    def stub_with(*http_stubbing_libraries)
      @http_stubbing_libraries = http_stubbing_libraries
    end

    def http_stubbing_libraries
      @http_stubbing_libraries ||= []
    end

    def register_request_matcher(name, &block)
      VCR.request_matchers.register(name, &block)
    end

    def ignore_hosts(*hosts)
      VCR.request_ignorer.ignore_hosts(*hosts)
    end
    alias ignore_host ignore_hosts

    def ignore_localhost=(value)
      VCR.request_ignorer.ignore_localhost = value
    end

    attr_writer :allow_http_connections_when_no_cassette
    def allow_http_connections_when_no_cassette?
      !!@allow_http_connections_when_no_cassette
    end

    def filter_sensitive_data(placeholder, tag = nil, &block)
      before_record(tag) do |interaction|
        interaction.filter!(call_block(block, interaction), placeholder)
      end

      before_playback(tag) do |interaction|
        interaction.filter!(placeholder, call_block(block, interaction))
      end
    end
  end
end

