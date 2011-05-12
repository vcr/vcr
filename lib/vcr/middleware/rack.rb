module VCR
  module Middleware
    class Rack
      include Common

      def initialize(*args)
        @mutex = Mutex.new
        super
      end

      def call(env)
        @mutex.synchronize do
          VCR.use_cassette(*cassette_arguments(env)) do
            @app.call(env)
          end
        end
      end
    end
  end
end
