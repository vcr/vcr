require 'webmock'

module VCR
  module HttpStubbingAdapters
    module WebMock
      include VCR::HttpStubbingAdapters::Common
      extend self

      MIN_PATCH_LEVEL   = '1.7.0'
      MAX_MINOR_VERSION = '1.7'

      def http_connections_allowed=(value)
        super
        update_webmock_allow_net_connect
      end

      def ignored_hosts=(hosts)
        super
        update_webmock_allow_net_connect
      end

      def vcr_request_from(webmock_request)
        VCR::Request.new(
          webmock_request.method,
          webmock_request.uri.to_s,
          webmock_request.body,
          webmock_request.headers
        )
      end

      def stub_requests(*args)
        super
        setup_webmock_hook
      end

      def create_stubs_checkpoint(cassette)
        webmock_checkpoints[cassette] = ::WebMock::StubRegistry.instance.request_stubs.dup
        super
      end

      def restore_stubs_checkpoint(cassette)
        ::WebMock::StubRegistry.instance.request_stubs = webmock_checkpoints.delete(cassette) || raise_no_checkpoint_error(cassette)
        super
      end

    private

      def update_webmock_allow_net_connect
        if http_connections_allowed?
          ::WebMock.allow_net_connect!
        else
          ::WebMock.disable_net_connect!(:allow => ignored_hosts)
        end
      end

      def webmock_checkpoints
        @webmock_checkpoints ||= {}
      end

      def version
        ::WebMock.version
      end

      def response_hash_for(response)
        {
          :body    => response.body,
          :status  => [response.status.code.to_i, response.status.message],
          :headers => response.headers
        }
      end

      def normalize_uri(uri)
        ::WebMock::Util::URI.normalize_uri(uri).to_s
      end

      def setup_webmock_hook
        ::WebMock.stub_request(:any, /.*/).with { |request|
          vcr_request = vcr_request_from(request)

          if uri_should_be_ignored?(request.uri)
            false
          elsif has_stubbed_response_for?(vcr_request)
            true
          elsif http_connections_allowed?
            false
          else
            raise_connections_disabled_error(vcr_request)
          end
        }.to_return(lambda { |request|
          response_hash_for stubbed_response_for(vcr_request_from(request))
        })
      end
    end
  end
end

WebMock.after_request(:real_requests_only => true) do |request, response|
  if VCR::HttpStubbingAdapters::WebMock.enabled?
    http_interaction = VCR::HTTPInteraction.new(
      VCR::HttpStubbingAdapters::WebMock.vcr_request_from(request),
      VCR::Response.new(
        VCR::ResponseStatus.new(
          response.status.first,
          response.status.last
        ),
        response.headers,
        response.body,
        '1.1'
      )
    )

    VCR.record_http_interaction(http_interaction)
  end
end

WebMock::NetConnectNotAllowedError.class_eval do
  undef stubbing_instructions
  def stubbing_instructions(*args)
    '.  ' + VCR::HttpStubbingAdapters::Common::RECORDING_INSTRUCTIONS
  end
end

