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

    class Rack
      include VCR::VariableArgsBlockCaller

      def initialize(app, &block)
        raise ArgumentError.new("You must provide a block to set the cassette options") unless block
        @app, @cassette_arguments_block, @mutex = app, block, Mutex.new
      end

      def call(env)
        @mutex.synchronize do
          VCR.use_cassette(*cassette_arguments(env)) do
            @app.call(env)
          end
        end
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
