require 'fileutils'
require 'vcr/util/hooks'

module VCR
  class Configuration
    include VCR::Hooks
    include VCR::VariableArgsBlockCaller

    define_hook :before_record
    define_hook :before_playback
    define_hook :after_library_hooks_loaded

    def initialize
      @allow_http_connections_when_no_cassette = nil
      @default_cassette_options = {
        :record            => :once,
        :match_requests_on => RequestMatcherRegistry::DEFAULT_MATCHERS
      }
    end

    attr_reader :cassette_library_dir
    def cassette_library_dir=(cassette_library_dir)
      @cassette_library_dir = cassette_library_dir
      FileUtils.mkdir_p(cassette_library_dir) if cassette_library_dir
    end

    attr_reader :default_cassette_options
    def default_cassette_options=(overrides)
      @default_cassette_options.merge!(overrides)
    end

    def hook_into(*hooks)
      hooks.each { |a| load_library_hook(a) }
      invoke_hook(:after_library_hooks_loaded)
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

  private

    def load_library_hook(hook)
      file = "vcr/library_hooks/#{hook}"
      require file
    rescue LoadError => e
      raise e unless e.message.include?(file) # in case FakeWeb/WebMock/etc itself is not available
      raise ArgumentError.new("#{hook.inspect} is not a supported VCR HTTP library hook.")
    end
  end
end

