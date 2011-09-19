require 'typhoeus'

module VCR
  module HttpStubbingAdapters
    module Typhoeus
      include VCR::HttpStubbingAdapters::Common
      extend self

      MIN_PATCH_LEVEL   = '0.2.1'
      MAX_MINOR_VERSION = '0.2'

      def after_adapters_loaded
        # ensure WebMock's Typhoeus adapter does not conflict with us here
        # (i.e. to double record requests or whatever).
        if defined?(::WebMock::HttpLibAdapters::TyphoeusAdapter)
          ::WebMock::HttpLibAdapters::TyphoeusAdapter.disable!
        end
      end

      def vcr_request_from(request)
        VCR::Request.new \
          request.method,
          request.url,
          request.body,
          request.headers
      end

    private

      def version
        ::Typhoeus::VERSION
      end

      class RequestHandler
        extend Forwardable

        attr_reader :request
        def_delegators :"VCR::HttpStubbingAdapters::Typhoeus",
          :enabled?,
          :uri_should_be_ignored?,
          :stubbed_response_for,
          :http_connections_allowed?,
          :vcr_request_from

        def initialize(request)
          @request = request
        end

        def handle
          if !enabled? || uri_should_be_ignored?(request.url)
            nil # allow the request to be performed
          elsif stubbed_response
            hydra_mock
          elsif http_connections_allowed?
            nil # allow the request to be performed and recorded
          else
            raise_connections_disabled_error
          end
        end

        def raise_connections_disabled_error
          VCR::HttpStubbingAdapters::Typhoeus.raise_connections_disabled_error(vcr_request)
        end

        def vcr_request
          @vcr_request ||= vcr_request_from(request)
        end

        def stubbed_response
          @stubbed_response ||= stubbed_response_for(vcr_request)
        end

        def typhoeus_response
          @typhoeus_response ||= ::Typhoeus::Response.new \
            :http_version   => stubbed_response.http_version,
            :code           => stubbed_response.status.code,
            :status_message => stubbed_response.status.message,
            :headers_hash   => stubbed_response_headers,
            :body           => stubbed_response.body
        end

        def hydra_mock
          @hydra_mock ||= ::Typhoeus::HydraMock.new(/.*/, :any).tap do |m|
            m.and_return(typhoeus_response)
          end
        end

        def stubbed_response_headers
          @stubbed_response_headers ||= {}.tap do |hash|
            stubbed_response.headers.each do |key, values|
              hash[key] = values.size == 1 ? values.first : values
            end if stubbed_response.headers
          end
        end
      end
    end
  end
end

Typhoeus::Hydra.after_request_before_on_complete do |request|
  if VCR::HttpStubbingAdapters::Typhoeus.enabled? && !request.response.mock?
    http_interaction = VCR::HTTPInteraction.new(
      VCR::HttpStubbingAdapters::Typhoeus.vcr_request_from(request),
      VCR::Response.new(
        VCR::ResponseStatus.new(
          request.response.code,
          request.response.status_message
        ),
        request.response.headers_hash,
        request.response.body,
        request.response.http_version
      )
    )

    VCR.record_http_interaction(http_interaction)
  end
end

Typhoeus::Hydra::Stubbing::SharedMethods.class_eval do
  undef find_stub_from_request
  def find_stub_from_request(request)
    VCR::HttpStubbingAdapters::Typhoeus::RequestHandler.new(request).handle
  end
end

