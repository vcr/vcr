require 'faraday'
require 'vcr/util/version_checker'
require 'vcr/request_handler'

VCR::VersionChecker.new('Faraday', Faraday::VERSION, '0.7.0', '0.7').check_version!

module VCR
  module Middleware
    class Faraday
      include VCR::Deprecations::Middleware::Faraday

      def initialize(app)
        super
        @app = app
      end

      def call(env)
        # Faraday must be exlusive here in case another library hook is being used.
        # We don't want double recording/double playback.
        VCR.library_hooks.exclusively_enabled(:faraday) do
          RequestHandler.new(@app, env).handle
        end
      end

      class RequestHandler < ::VCR::RequestHandler
        attr_reader :app, :env
        def initialize(app, env)
          @app, @env = app, env
        end

      private

        def vcr_request
          @vcr_request ||= VCR::Request.new \
            env[:method],
            env[:url].to_s,
            env[:body],
            env[:request_headers]
        end

        def response_for(env)
          response = env[:response]

          VCR::Response.new(
            VCR::ResponseStatus.new(response.status, nil),
            response.headers,
            response.body,
            '1.1'
          )
        end

        def on_ignored_request
          app.call(env)
        end

        def on_stubbed_request
          headers = env[:response_headers] ||= ::Faraday::Utils::Headers.new
          headers.update stubbed_response.headers if stubbed_response.headers
          env.update :status => stubbed_response.status.code, :body => stubbed_response.body

          faraday_response = ::Faraday::Response.new
          faraday_response.finish(env) unless env[:parallel_manager]
          env[:response] = faraday_response
        end

        def on_recordable_request
          app.call(env).on_complete do |env|
            VCR.record_http_interaction(VCR::HTTPInteraction.new(vcr_request, response_for(env)))
          end
        end
      end
    end
  end
end
