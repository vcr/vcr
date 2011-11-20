require 'vcr/util/version_checker'
require 'vcr/request_handler'
require 'webmock'

VCR::VersionChecker.new('WebMock', WebMock.version, '1.7.8', '1.7').check_version!

module VCR
  class LibraryHooks
    module WebMock
      module Helpers
        def vcr_request_from(webmock_request)
          VCR::Request.new \
            webmock_request.method,
            webmock_request.uri.to_s,
            webmock_request.body,
            webmock_request.headers
        end

        def vcr_response_from(response)
          VCR::Response.new \
            VCR::ResponseStatus.new(response.status.first, response.status.last),
            response.headers,
            response.body,
            nil
        end
      end

      class RequestHandler < ::VCR::RequestHandler
        include Helpers

        attr_reader :request
        def initialize(request)
          @request = request
        end

      private

        def vcr_request
          @vcr_request ||= vcr_request_from(request)
        end

        def on_stubbed_request
          {
            :body    => stubbed_response.body,
            :status  => [stubbed_response.status.code.to_i, stubbed_response.status.message],
            :headers => stubbed_response.headers
          }
        end
      end

      extend Helpers

      ::WebMock.globally_stub_request { |req| RequestHandler.new(req).handle }

      ::WebMock.after_request(:real_requests_only => true) do |request, response|
        unless VCR.library_hooks.disabled?(:webmock)
          http_interaction = VCR::HTTPInteraction.new \
            vcr_request_from(request),
            vcr_response_from(response)

          VCR.record_http_interaction(http_interaction)
        end
      end
    end
  end
end

class << WebMock
  # ensure HTTP requests are always allowed; VCR takes care of disallowing
  # them at the appropriate times in its hook
  undef net_connect_allowed?
  def net_connect_allowed?(*args)
    true
  end
end

