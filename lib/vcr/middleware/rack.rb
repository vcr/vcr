module VCR
  module Middleware
    class Rack
      include Common

      def call(env)
        Thread.exclusive do
          VCR.use_cassette(*cassette_arguments(env)) do
            @app.call(env)
          end
        end
      end
    end
  end
end
