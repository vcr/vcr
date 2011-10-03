require 'vcr/util/version_checker'
require 'typhoeus'

VCR::VersionChecker.new('Typhoeus', Typhoeus::VERSION, '0.2.1', '0.2').check_version!

module VCR
  class HTTPStubbingAdapters
    module Typhoeus
      class RequestHandler
        extend Forwardable

        attr_reader :request
        def_delegators :VCR, :real_http_connections_allowed?

        def initialize(request)
          @request = request
        end

        def handle
          if disabled? || VCR.request_ignorer.ignore?(vcr_request)
            nil # allow the request to be performed
          elsif stubbed_response
            hydra_mock
          elsif real_http_connections_allowed?
            nil # allow the request to be performed and recorded
          else
            raise VCR::HTTPConnectionNotAllowedError.new(vcr_request)
          end
        end

      private

        def disabled?
          VCR.http_stubbing_adapters.disabled?(:typhoeus)
        end

        def vcr_request
          @vcr_request ||= self.class.vcr_request_from(request)
        end

        def self.vcr_request_from(request)
          VCR::Request.new \
            request.method,
            request.url,
            request.body,
            request.headers
        end

        def self.vcr_response_from(response)
          VCR::Response.new \
            VCR::ResponseStatus.new(response.code, response.status_message),
            response.headers_hash,
            response.body,
            response.http_version
        end

        def stubbed_response
          @stubbed_response ||= VCR.http_interactions.response_for(vcr_request)
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

        ::Typhoeus::Hydra.after_request_before_on_complete do |request|
          unless VCR.http_stubbing_adapters.disabled?(:typhoeus) || request.response.mock?
            http_interaction = VCR::HTTPInteraction.new(vcr_request_from(request), vcr_response_from(request.response))
            VCR.record_http_interaction(http_interaction)
          end
        end

      end
    end
  end
end

# TODO: add Typhoeus::Hydra.register_stub_finder API to Typhoeus
#       so we can use that instead of monkey-patching it.
Typhoeus::Hydra::Stubbing::SharedMethods.class_eval do
  undef find_stub_from_request
  def find_stub_from_request(request)
    VCR::HTTPStubbingAdapters::Typhoeus::RequestHandler.new(request).handle
  end
end

VCR.configuration.after_http_stubbing_adapters_loaded do
  # ensure WebMock's Typhoeus adapter does not conflict with us here
  # (i.e. to double record requests or whatever).
  if defined?(WebMock::HttpLibAdapters::TyphoeusAdapter)
    WebMock::HttpLibAdapters::TyphoeusAdapter.disable!
  end
end

