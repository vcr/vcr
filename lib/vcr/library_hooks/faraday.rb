require 'vcr/middleware/faraday'

module VCR
  class LibraryHooks
    # @private
    module Faraday
      # @private
      module BuilderClassExtension
        def new(*args)
          super.extend BuilderInstanceExtension
        end

        ::Faraday::Builder.extend self
      end

      # @private
      module BuilderInstanceExtension
        def lock!(*args)
          insert_vcr_middleware
          super
        end

      private

        def insert_vcr_middleware
          return if handlers.any? { |h| h.klass == VCR::Middleware::Faraday }
          adapter_index = handlers.index { |h| h.klass < ::Faraday::Adapter }
          insert_before(adapter_index, VCR::Middleware::Faraday)
        end
      end
    end
  end
end

