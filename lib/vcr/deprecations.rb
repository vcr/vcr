module VCR
  module HttpStubbingAdapters
    module Common
      def ignore_localhost?
        VCR::Config.ignore_localhost?
      end
    end
  end

  module Config
    def http_stubbing_library
      warn "WARNING: `VCR::Config.http_stubbing_library` is deprecated.  Use `VCR::Config.http_stubbing_libraries` instead."
      @http_stubbing_libraries && @http_stubbing_libraries.first
    end

    def http_stubbing_library=(library)
      warn "WARNING: `VCR::Config.http_stubbing_library = #{library.inspect}` is deprecated.  Use `VCR::Config.stub_with #{library.inspect}` instead."
      stub_with library
    end

    def ignore_localhost?
      warn "WARNING: `VCR::Config.ignore_localhost?` is deprecated.  Check the list of ignored hosts using `VCR::Config.ignored_hosts` instead."
      (VCR::LOCALHOST_ALIASES - ignored_hosts).empty?
    end
  end

  class Cassette
    def allow_real_http_requests_to?(uri)
      warn "WARNING: VCR::Cassette#allow_real_http_requests_to? is deprecated and should no longer be used."
      VCR::Config.uri_should_be_ignored?(uri.to_s)
    end

    private

    def deprecate_old_cassette_options(options)
      message = "VCR's :allow_real_http cassette option is deprecated.  Instead, use the ignore_localhost configuration option."
      if options[:allow_real_http] == :localhost
        @original_ignored_hosts = VCR::Config.ignored_hosts.dup
        VCR::Config.ignored_hosts.clear
        VCR::Config.ignore_hosts *VCR::LOCALHOST_ALIASES
        Kernel.warn "WARNING: #{message}"
      elsif options[:allow_real_http]
        raise ArgumentError.new(message)
      end
    end

    def restore_ignore_localhost_for_deprecation
      if defined?(@original_ignored_hosts)
        VCR::Config.ignored_hosts.clear
        VCR::Config.ignore_hosts *@original_ignored_hosts
      end
    end
  end
end
