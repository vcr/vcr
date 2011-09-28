module VCR
  module Middleware
    module Common
      def initialize(app, &block)
        raise ArgumentError.new("You must provide a block to set the cassette options") unless block
        @app, @cassette_arguments_block = app, block
      end

    private

      def cassette_arguments(env)
        arguments = CassetteArguments.new
        @cassette_arguments_block.call(arguments, env)
        [arguments.name, arguments.options]
      end
    end
  end
end
