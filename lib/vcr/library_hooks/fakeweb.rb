require 'vcr/util/version_checker'
require 'fakeweb'
require 'net/http'
require 'vcr/extensions/net_http_response'
require 'vcr/request_handler'
require 'set'

VCR::VersionChecker.new('FakeWeb', FakeWeb::VERSION, '1.3.0').check_version!

module VCR
  class LibraryHooks
    # @private
    module FakeWeb
      # @private
      class RequestHandler < ::VCR::RequestHandler
        attr_reader :net_http, :request, :request_body, :response_block
        def initialize(net_http, request, request_body = nil, &response_block)
          @net_http, @request, @request_body, @response_block =
           net_http,  request,  request_body,  response_block
          @stubbed_response, @vcr_response, @recursing = nil, nil, false
        end

        def handle
          super
        ensure
          invoke_after_request_hook(@vcr_response) unless @recursing
        end

      private

        def externally_stubbed?
          ::FakeWeb.registered_uri?(request_method, uri)
        end

        def on_externally_stubbed_request
          # just perform the request--FakeWeb will handle it
          perform_request(:started)
        end

        def on_recordable_request
          perform_request(net_http.started?, :record_interaction)
        end

        def on_stubbed_by_vcr_request
          with_exclusive_fakeweb_stub(stubbed_response) do
            # force it to be considered started since it doesn't
            # recurse in this case like the others.
            perform_request(:started)
          end
        end

        def on_ignored_request
          perform_request(net_http.started?)
        end

        def perform_request(started, record_interaction = false)
          # Net::HTTP calls #request recursively in certain circumstances.
          # We only want to record the request when the request is started, as
          # that is the final time through #request.
          unless started
            @recursing = true
            request.instance_variable_set(:@__vcr_request_handler, recursive_request_handler)
            return net_http.request_without_vcr(request, request_body, &response_block)
          end

          net_http.request_without_vcr(request, request_body) do |response|
            @vcr_response = vcr_response_from(response)

            if record_interaction
              VCR.record_http_interaction VCR::HTTPInteraction.new(vcr_request, @vcr_response)
            end

            response.extend VCR::Net::HTTPResponse # "unwind" the response
            response_block.call(response) if response_block
          end
        end

        def uri
          @uri ||= ::FakeWeb::Utility.request_uri_as_string(net_http, request)
        end

        def response_hash(response)
          (response.headers || {}).merge(
            :body   => response.body,
            :status => [response.status.code.to_s, response.status.message]
          )
        end

        def with_exclusive_fakeweb_stub(response)
          original_map = ::FakeWeb::Registry.instance.uri_map.dup
          ::FakeWeb.clean_registry
          ::FakeWeb.register_uri(:any, /.*/, response_hash(response))

          begin
            return yield
          ensure
            ::FakeWeb::Registry.instance.uri_map = original_map
          end
        end

        def request_method
          request.method.downcase.to_sym
        end

        def vcr_request
          @vcr_request ||= VCR::Request.new \
            request_method,
            uri,
            (request_body || request.body),
            request.to_hash
        end

        def vcr_response_from(response)
          VCR::Response.new \
            VCR::ResponseStatus.new(response.code.to_i, response.message),
            response.to_hash,
            response.body,
            response.http_version
        end

        def recursive_request_handler
          @recursive_request_handler ||= RecursiveRequestHandler.new(
            @after_hook_typed_request.type, @stubbed_response, @vcr_request,
            @net_http, @request, @request_body, &@response_block
          )
        end
      end

      # @private
      class RecursiveRequestHandler < RequestHandler
        attr_reader :stubbed_response

        def initialize(request_type, stubbed_response, vcr_request, *args, &response_block)
          @request_type, @stubbed_response, @vcr_request =
           request_type,  stubbed_response,  vcr_request
          super(*args)
        end

        def handle
          set_typed_request_for_after_hook(@request_type)
          send "on_#{@request_type}_request"
        ensure
          invoke_after_request_hook(@vcr_response)
        end

        def request_type(*args)
          @request_type
        end
      end
    end
  end
end

# @private
module Net
  # @private
  class HTTP
    unless method_defined?(:request_with_vcr)
      def request_with_vcr(request, *args, &block)
        if VCR.turned_on?
          handler = request.instance_eval do
            remove_instance_variable(:@__vcr_request_handler) if defined?(@__vcr_request_handler)
          end || VCR::LibraryHooks::FakeWeb::RequestHandler.new(self, request, *args, &block)

          handler.handle
        else
          request_without_vcr(request, *args, &block)
        end
      end

      alias request_without_vcr request
      alias request request_with_vcr
    end
  end
end

# @private
module FakeWeb
  class << self
    # ensure HTTP requests are always allowed; VCR takes care of disallowing
    # them at the appropriate times in its hook
    def allow_net_connect_with_vcr?(*args)
      VCR.turned_on? ? true : allow_net_connect_without_vcr?(*args)
    end

    alias allow_net_connect_without_vcr? allow_net_connect?
    alias allow_net_connect? allow_net_connect_with_vcr?
  end unless respond_to?(:allow_net_connect_with_vcr?)
end

VCR.configuration.after_library_hooks_loaded do
  if defined?(WebMock)
    raise ArgumentError.new("You have configured VCR to hook into both :fakeweb and :webmock. You cannot use both.")
  end
  ::Kernel.warn "WARNING: VCR's FakeWeb integration is deprecated and will be removed in VCR 3.0."
end

