require 'vcr/util/version_checker'
require 'vcr/request_handler'
require 'typhoeus'

if Float(Typhoeus::VERSION[/^\d+\.\d+/]) < 0.5
  require 'vcr/library_hooks/typhoeus_0.4'
else
  VCR::VersionChecker.new('Typhoeus', Typhoeus::VERSION, '0.5.0').check_version!

  module VCR
    class LibraryHooks
      # @private
      module Typhoeus
        # @private
        class RequestHandler < ::VCR::RequestHandler
          attr_reader :request
          def initialize(request)
            @request = request
            request.block_connection = false if VCR.turned_on?
          end

          def vcr_request
            @vcr_request ||= VCR::Request.new \
              request.options.fetch(:method, :get),
              request.url,
              request_body,
              request.options.fetch(:headers, {})
          end

        private

          def externally_stubbed?
            ::Typhoeus::Expectation.find_by(request)
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
              :headers        => stubbed_response_headers,
              :body           => stubbed_response.body,
              :effective_url  => stubbed_response.adapter_metadata.fetch('effective_url', request.url),
              :mock           => true
          end

          def stubbed_response_headers
            @stubbed_response_headers ||= {}.tap do |hash|
              stubbed_response.headers.each do |key, values|
                hash[key] = values.size == 1 ? values.first : values
              end if stubbed_response.headers
            end
          end

          if ::Typhoeus::Request.method_defined?(:encoded_body)
            def request_body
              request.encoded_body
            end
          else
            def request_body
              request.options.fetch(:body, "")
            end
          end
        end

        # @private
        def self.vcr_response_from(response)
          VCR::Response.new \
            VCR::ResponseStatus.new(response.code, response.status_message),
            response.headers,
            response.body,
            response.http_version,
            { "effective_url" => response.effective_url }
        end

        ::Typhoeus.on_complete do |response|
          request = response.request
          unless VCR.library_hooks.disabled?(:typhoeus)
            vcr_response = vcr_response_from(response)
            typed_vcr_request = request.send(:remove_instance_variable, :@__typed_vcr_request)

            unless request.response.mock
              http_interaction = VCR::HTTPInteraction.new(typed_vcr_request, vcr_response)
              VCR.record_http_interaction(http_interaction)
            end

            VCR.configuration.invoke_hook(:after_http_request, typed_vcr_request, vcr_response)
          end
        end

        ::Typhoeus.before do |request|
          if response = VCR::LibraryHooks::Typhoeus::RequestHandler.new(request).handle
            request.finish(response)
          else
            true
          end
        end
      end
    end
  end
end

VCR.configuration.after_library_hooks_loaded do
  # ensure WebMock's Typhoeus adapter does not conflict with us here
  # (i.e. to double record requests or whatever).
  if defined?(WebMock::HttpLibAdapters::TyphoeusAdapter)
    WebMock::HttpLibAdapters::TyphoeusAdapter.disable!
  end
end

