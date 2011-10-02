require 'vcr/http_stubbing_adapters/common'
require 'webmock'

VCR::VersionChecker.new('WebMock', WebMock.version, '1.7.0', '1.7').check_version!

module VCR
  class HTTPStubbingAdapters
    module WebMock

      # helper methods
      class << self
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

        def disabled?
          VCR.http_stubbing_adapters.disabled?(:webmock)
        end
      end

      GLOBAL_VCR_HOOK = ::WebMock::RequestStub.new(:any, /.*/).tap do |stub|
        stub.with { |request|
          vcr_request = vcr_request_from(request)

          if disabled? || VCR.request_ignorer.ignore?(vcr_request)
            false
          elsif VCR.http_interactions.has_interaction_matching?(vcr_request)
            true
          elsif VCR.real_http_connections_allowed?
            false
          else
            VCR::HTTPStubbingAdapters::Common.raise_connections_disabled_error(vcr_request)
          end
        }.to_return(lambda { |request|
          response_hash_for VCR.http_interactions.response_for(vcr_request_from(request))
        })
      end

      ::WebMock::StubRegistry.instance.register_request_stub(GLOBAL_VCR_HOOK)

      ::WebMock.after_request(:real_requests_only => true) do |request, response|
        unless disabled?
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
    self.request_stubs = [VCR::HTTPStubbingAdapters::WebMock::GLOBAL_VCR_HOOK]
  end
end

