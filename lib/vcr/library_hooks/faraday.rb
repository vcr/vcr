Kernel.warn "WARNING: `VCR.config { |c| c.stub_with :faraday }` is deprecated. " +
            "Just use `VCR::Middleware::Faraday` in your faraday stack."

