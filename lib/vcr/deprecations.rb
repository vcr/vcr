module VCR
  def config
    warn "WARNING: `VCR.config` is deprecated.  Use VCR.configure instead."
    configure { |c| yield c }
  end

  def self.const_missing(const)
    return super unless const == :Config
    warn "WARNING: `VCR::Config` is deprecated.  Use VCR.configuration instead."
    configuration
  end
end
