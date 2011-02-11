module VCR
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
