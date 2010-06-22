module VCR
  class Cassette
    def allow_real_http_requests_to?(uri)
      warn "WARNING: VCR::Cassette#allow_real_http_requests_to? is deprecated and should no longer be used."
      VCR.http_stubbing_adapter.ignore_localhost? && VCR::LOCALHOST_ALIASES.include?(uri.host)
    end

    private

    def deprecate_old_cassette_options(options)
      message = "VCR's :allow_real_http cassette option is deprecated.  Instead, use the ignore_localhost configuration option."
      if options[:allow_real_http] == :localhost
        @original_ignore_localhost = VCR.http_stubbing_adapter.ignore_localhost?
        VCR.http_stubbing_adapter.ignore_localhost = true
        Kernel.warn "WARNING: #{message}"
      elsif options[:allow_real_http]
        raise ArgumentError.new(message)
      end
    end

    def restore_ignore_localhost_for_deprecation
      if defined?(@original_ignore_localhost)
        VCR.http_stubbing_adapter.ignore_localhost = @original_ignore_localhost
      end
    end
  end
end
