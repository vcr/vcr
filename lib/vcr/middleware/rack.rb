module VCR
  module Middleware
    class Rack
      def initialize(app, &block)
        raise ArgumentError.new("You must provide a block to set the cassette options") unless block
        @app, @cassette_arguments_block = app, block
      end

      def call(env)
        VCR.use_cassette(*cassette_arguments(env)) do
          @app.call(env)
        end
      end

      private

        def cassette_arguments(env)
          arguments = CassetteArguments.new

          block_args = [arguments]
          block_args << env unless @cassette_arguments_block.arity == 1

          @cassette_arguments_block.call(*block_args)
          [arguments.name, arguments.options]
        end
    end
  end
end
