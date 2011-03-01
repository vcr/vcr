module VCR
  module HttpStubbingAdapters
    module FakeWeb
      def self.const_missing(const)
        return super unless const == :LOCALHOST_REGEX
        warn "WARNING: `VCR::HttpStubbingAdapters::FakeWeb::LOCALHOST_REGEX` is deprecated."
        VCR::Regexes.url_regex_for_hosts(VCR::LOCALHOST_ALIASES)
      end
    end
  end
end
