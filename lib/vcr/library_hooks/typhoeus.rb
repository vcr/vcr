require 'vcr/util/version_checker'
require 'vcr/request_handler'
require 'typhoeus'

VCR::VersionChecker.new('Typhoeus', Typhoeus::VERSION, '0.3.2', '0.3').check_version!

module VCR
  class LibraryHooks
    # @private
    module Typhoeus
      # @private
      module Helpers
        def vcr_request_from(request)
          VCR::Request.new \
            request.method,
            request.url,
            request.body,
            request.headers
        end

        def vcr_response_from(response)
          VCR::Response.new \
            VCR::ResponseStatus.new(response.code, response.status_message),
            response.headers_hash,
            response.body,
            response.http_version
        end
      end

      class RequestHandler < ::VCR::RequestHandler
        include Helpers

        attr_reader :request
        def initialize(request)
          @request = request
        end

      private

        def on_unhandled_request
          invoke_after_request_hook(nil)
          super
        end

        def vcr_request
          @vcr_request ||= vcr_request_from(request)
        end

        def on_stubbed_request
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

      extend Helpers
      ::Typhoeus::Hydra.after_request_before_on_complete do |request|
        unless VCR.library_hooks.disabled?(:typhoeus)
          vcr_request, vcr_response = vcr_request_from(request), vcr_response_from(request.response)

          unless request.response.mock?
            http_interaction = VCR::HTTPInteraction.new(vcr_request, vcr_response)
            VCR.record_http_interaction(http_interaction)
          end

          VCR.configuration.invoke_hook(:after_http_request, vcr_request, vcr_response)
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
  # ensure WebMock's Typhoeus adapter does not conflict with us here
  # (i.e. to double record requests or whatever).
  if defined?(WebMock::HttpLibAdapters::TyphoeusAdapter)
    WebMock::HttpLibAdapters::TyphoeusAdapter.disable!
  end
end

