module VCR
  module Middleware
    class CassetteArguments
      def initialize
        @options = {}
      end

      def name(name = nil)
        @name = name if name
        @name
      end

      def options(options = {})
        @options.merge!(options)
      end
    end
  end
end
