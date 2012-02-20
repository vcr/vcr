require 'vcr/util/version_checker'
require 'vcr/request_handler'
require 'webmock'

VCR::VersionChecker.new('WebMock', WebMock.version, '1.8.0', '1.8').check_version!

module VCR
  class LibraryHooks
    # @private
    module WebMock
      class RequestHandler < ::VCR::RequestHandler

        attr_reader :request
        def initialize(request)
          @request = request
        end

      private

        def set_typed_request_for_after_hook(*args)
          super
          request.instance_variable_set(:@__typed_vcr_request, @after_hook_typed_request)
        end

        def vcr_request
          @vcr_request ||= VCR::Request.new \
            request.method,
            request.uri.to_s,
            request.body,
            request_headers
        end

        if defined?(::Excon)
          # @private
          def request_headers
            return nil unless request.headers

            # WebMock hooks deeply into a Excon at a place where it manually adds a "Host"
            # header, but this isn't a header we actually care to store...
            request.headers.dup.tap do |headers|
              headers.delete("Host")
            end
          end
        else
          # @private
          def request_headers
            request.headers
          end
        end

        def on_unhandled_request
          invoke_after_request_hook(nil)
          super
        end

        def on_stubbed_request
          {
            :body    => stubbed_response.body,
            :status  => [stubbed_response.status.code.to_i, stubbed_response.status.message],
            :headers => stubbed_response.headers
          }
        end
      end

      # @private
      def self.vcr_response_from(response)
        VCR::Response.new \
          VCR::ResponseStatus.new(response.status.first, response.status.last),
          response.headers,
          response.body,
          nil
      end

      ::WebMock.globally_stub_request { |req| RequestHandler.new(req).handle }

      ::WebMock.after_request(:real_requests_only => true) do |request, response|
        unless VCR.library_hooks.disabled?(:webmock)
          http_interaction = VCR::HTTPInteraction.new \
            request.send(:instance_variable_get, :@__typed_vcr_request),
            vcr_response_from(response)

          VCR.record_http_interaction(http_interaction)
        end
      end

      ::WebMock.after_request do |request, response|
        unless VCR.library_hooks.disabled?(:webmock)
          typed_vcr_request = request.send(:remove_instance_variable, :@__typed_vcr_request)
          VCR.configuration.invoke_hook(:after_http_request, typed_vcr_request, vcr_response_from(response))
        end
      end
    end
  end
end

# @private
module WebMock
  class << self
    # ensure HTTP requests are always allowed; VCR takes care of disallowing
    # them at the appropriate times in its hook
    def net_connect_allowed_with_vcr?(*args)
      VCR.turned_on? ? true : net_connect_allowed_without_vcr?
    end

    alias net_connect_allowed_without_vcr? net_connect_allowed?
    alias net_connect_allowed? net_connect_allowed_with_vcr?
  end unless respond_to?(:net_connect_allowed_with_vcr?)
end

