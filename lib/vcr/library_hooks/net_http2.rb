require 'vcr/middleware/net_http2'

module VCR
  class LibraryHooks
    # @private
    module NetHttp2
      # @private
      module BuilderClassExtension
        def new(*args)
          super.extend BuilderInstanceExtension
        end
      end

      # @private
      module BuilderInstanceExtension
        def lock!(*args)
          insert_vcr_middleware
          super
        end

      private

        def insert_vcr_middleware
          return if handlers.any? { |h| h.klass == VCR::Middleware::NetHttp2 }
          adapter_index = handlers.index { |h| h.klass < ::NetHttp2::Adapter }
          adapter_index ||= handlers.size
          warn_about_after_adapter_middleware(adapter_index)
          insert_before(adapter_index, VCR::Middleware::NetHttp2)
        end

        def warn_about_after_adapter_middleware(adapter_index)
          after_adapter_middleware_count = (handlers.size - adapter_index - 1)
          return if after_adapter_middleware_count < 1

          after_adapter_middlewares = handlers.last(after_adapter_middleware_count)
          warn "WARNING: The NetHttp2 connection stack contains middleware after " +
               "the HTTP adapter (#{after_adapter_middlewares.map(&:inspect).join(', ')}). " +
               "This is a non-standard configuration and VCR may not be able to " +
               "record the HTTP requests made through this NetHttp2 connection."
        end
      end
    end
  end
end
