module VCR
  class RequestHandler
    def handle
      invoke_before_request_hook
      return on_ignored_request    if should_ignore?
      return on_stubbed_request    if stubbed_response
      return on_recordable_request if VCR.real_http_connections_allowed?
      on_connection_not_allowed
    end

  private

    def invoke_before_request_hook
      return if disabled?
      VCR.configuration.invoke_hook(:before_http_request, tag = nil, vcr_request)
    end

    def should_ignore?
      disabled? || VCR.request_ignorer.ignore?(vcr_request)
    end

    def disabled?
      VCR.library_hooks.disabled?(library_name)
    end

    def stubbed_response
      @stubbed_response ||= VCR.http_interactions.response_for(vcr_request)
    end

    def library_name
      # extracts `:typhoeus` from `VCR::LibraryHooks::Typhoeus::RequestHandler`
      @library_name ||= self.class.name.split('::')[-2].downcase.to_sym
    end

    # Subclasses can implement these
    def on_ignored_request
    end

    def on_stubbed_request
    end

    def on_recordable_request
    end

    def on_connection_not_allowed
      raise VCR::Errors::UnhandledHTTPRequestError.new(vcr_request)
    end
  end
end
