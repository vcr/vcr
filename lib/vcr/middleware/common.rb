module VCR
  module Middleware
    class CassetteArguments
      def initialize
        @name    = nil
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

    module Common
      include VCR::VariableArgsBlockCaller

      def initialize(app, &block)
        raise ArgumentError.new("You must provide a block to set the cassette options") unless block
        @app, @cassette_arguments_block = app, block
      end

    private

      def cassette_arguments(env)
        arguments = CassetteArguments.new
        call_block(@cassette_arguments_block, arguments, env)
        [arguments.name, arguments.options]
      end
    end
  end
end
