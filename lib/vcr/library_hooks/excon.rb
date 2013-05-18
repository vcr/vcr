require 'vcr/middleware/excon'

Excon.defaults[:middlewares] << VCR::Middleware::Excon

VCR.configuration.after_library_hooks_loaded do
  # ensure WebMock's Excon adapter does not conflict with us here
  # (i.e. to double record requests or whatever).
  if defined?(WebMock::HttpLibAdapters::ExconAdapter)
    WebMock::HttpLibAdapters::ExconAdapter.disable!
  end
end

