require 'vcr/util/version_checker'
require 'vcr/request_handler'
require 'webmock'

VCR::VersionChecker.new('WebMock', WebMock.version, '1.7.0', '1.7').check_version!

module VCR
  class LibraryHooks
    module WebMock
      module Helpers
        def response_hash_for(response)
          {
            :body    => response.body,
            :status  => [response.status.code.to_i, response.status.message],
            :headers => response.headers
          }
        end

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
            '1.1'
        end
      end

      class RequestHandler < ::VCR::RequestHandler
        include Helpers

        attr_reader :request
        def initialize(request)
          @request = request
        end

      private

        def stubbed_response
          VCR.http_interactions.has_interaction_matching?(vcr_request)
        end

        def vcr_request
          @vcr_request ||= vcr_request_from(request)
        end

        def on_ignored_request;    false; end
        def on_stubbed_request;    true;  end
        def on_recordable_request; false; end
      end

      extend Helpers

      GLOBAL_VCR_HOOK = ::WebMock::RequestStub.new(:any, /.*/).tap do |stub|
        stub.with { |request|
          RequestHandler.new(request).handle
        }.to_return(lambda { |request|
          response_hash_for VCR.http_interactions.response_for(vcr_request_from(request))
        })
      end

      ::WebMock::StubRegistry.instance.register_request_stub(GLOBAL_VCR_HOOK)

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

WebMock::StubRegistry.class_eval do
  # ensure our VCR hook is not removed when WebMock is reset
  undef reset!
  def reset!
    self.request_stubs = [VCR::LibraryHooks::WebMock::GLOBAL_VCR_HOOK]
  end
end

