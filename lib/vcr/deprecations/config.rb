module VCR
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
end
