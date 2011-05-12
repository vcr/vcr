require 'fileutils'
require 'vcr/util/hooks'

module VCR
  module Config
    include VCR::Hooks
    include VCR::VariableArgsBlockCaller
    extend self

    define_hook :before_record
    define_hook :before_playback

    attr_reader :cassette_library_dir
    def cassette_library_dir=(cassette_library_dir)
      @cassette_library_dir = cassette_library_dir
      FileUtils.mkdir_p(cassette_library_dir) if cassette_library_dir
    end

    attr_writer :default_cassette_options
    def default_cassette_options
      @default_cassette_options ||= {}
      @default_cassette_options[:match_requests_on] ||= RequestMatcher::DEFAULT_MATCH_ATTRIBUTES
      @default_cassette_options[:record] ||= :once
      @default_cassette_options[:record_errors] ||= false
      @default_cassette_options
    end

    def stub_with(*http_stubbing_libraries)
      @http_stubbing_libraries = http_stubbing_libraries
    end

    def http_stubbing_libraries
      @http_stubbing_libraries ||= []
    end

    def ignore_hosts(*hosts)
      ignored_hosts.push(*hosts).uniq!
      VCR.http_stubbing_adapter.ignored_hosts = ignored_hosts if http_stubbing_libraries.any?
    end
    alias ignore_host ignore_hosts

    def ignored_hosts
      @ignored_hosts ||= []
    end

    def ignore_localhost=(value)
      if value
        ignore_hosts *VCR::LOCALHOST_ALIASES
      else
        ignored_hosts.reject! { |h| VCR::LOCALHOST_ALIASES.include?(h) }
      end
    end

    def allow_http_connections_when_no_cassette=(value)
      @allow_http_connections_when_no_cassette = value
      VCR.http_stubbing_adapter.set_http_connections_allowed_to_default if http_stubbing_libraries.any?
    end

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

    def uri_should_be_ignored?(uri)
      uri = URI.parse(uri) unless uri.respond_to?(:host)
      ignored_hosts.include?(uri.host)
    end
  end
end

