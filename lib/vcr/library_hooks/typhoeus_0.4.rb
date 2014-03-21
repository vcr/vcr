VCR::VersionChecker.new('Typhoeus', Typhoeus::VERSION, '0.3.2').check_version!

module VCR
  class LibraryHooks
    # @private
    module Typhoeus
      # @private
      class RequestHandler < ::VCR::RequestHandler
        attr_reader :request
        def initialize(request)
          @request = request
        end

        def vcr_request
          @vcr_request ||= VCR::Request.new \
            request.method,
            request.url,
            request.body,
            request.headers
        end

      private

        def externally_stubbed?
          ::Typhoeus::Hydra.stubs.detect { |stub| stub.matches?(request) }
        end

        def set_typed_request_for_after_hook(*args)
          super
          request.instance_variable_set(:@__typed_vcr_request, @after_hook_typed_request)
        end

        def on_unhandled_request
          invoke_after_request_hook(nil)
          super
        end

        def on_stubbed_by_vcr_request
          ::Typhoeus::Response.new \
            :http_version   => stubbed_response.http_version,
            :code           => stubbed_response.status.code,
            :status_message => stubbed_response.status.message,
            :headers_hash   => stubbed_response_headers,
            :body           => stubbed_response.body
        end

        def stubbed_response_headers
          @stubbed_response_headers ||= {}.tap do |hash|
            stubbed_response.headers.each do |key, values|
              hash[key] = values.size == 1 ? values.first : values
            end if stubbed_response.headers
          end
        end
      end

      # @private
      def self.vcr_response_from(response)
        VCR::Response.new \
          VCR::ResponseStatus.new(response.code, response.status_message),
          response.headers_hash,
          response.body,
          response.http_version
      end

      ::Typhoeus::Hydra.after_request_before_on_complete do |request|
        unless VCR.library_hooks.disabled?(:typhoeus)
          vcr_response = vcr_response_from(request.response)
          typed_vcr_request = request.send(:remove_instance_variable, :@__typed_vcr_request)

          unless request.response.mock?
            http_interaction = VCR::HTTPInteraction.new(typed_vcr_request, vcr_response)
            VCR.record_http_interaction(http_interaction)
          end

          VCR.configuration.invoke_hook(:after_http_request, typed_vcr_request, vcr_response)
        end
      end

      ::Typhoeus::Hydra.register_stub_finder do |request|
        VCR::LibraryHooks::Typhoeus::RequestHandler.new(request).handle
      end
    end
  end
end

# @private
module Typhoeus
  class << Hydra
    # ensure HTTP requests are always allowed; VCR takes care of disallowing
    # them at the appropriate times in its hook
    def allow_net_connect_with_vcr?(*args)
      VCR.turned_on? ? true : allow_net_connect_without_vcr?
    end

    alias allow_net_connect_without_vcr? allow_net_connect?
    alias allow_net_connect? allow_net_connect_with_vcr?
  end unless Hydra.respond_to?(:allow_net_connect_with_vcr?)
end

VCR.configuration.after_library_hooks_loaded do
  ::Kernel.warn "WARNING: VCR's Typhoeus 0.4 integration is deprecated and will be removed in VCR 3.0."
end

