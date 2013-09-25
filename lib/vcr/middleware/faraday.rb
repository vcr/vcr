require 'faraday'
require 'vcr/util/version_checker'
require 'vcr/request_handler'

VCR::VersionChecker.new('Faraday', Faraday::VERSION, '0.7.0', '0.9').check_version!

module VCR
  # Contains middlewares for use with different libraries.
  module Middleware
    # Faraday middleware that VCR uses to record and replay HTTP requests made through
    # Faraday.
    #
    # @note You can either insert this middleware into the Faraday middleware stack
    #  yourself or configure {VCR::Configuration#hook_into} to hook into `:faraday`.
    class Faraday
      include VCR::Deprecations::Middleware::Faraday

      # Constructs a new instance of the Faraday middleware.
      #
      # @param [#call] app the faraday app
      def initialize(app)
        super
        @app = app
      end

      # Handles the HTTP request being made through Faraday
      #
      # @param [Hash] env the Faraday request env hash
      def call(env)
        return if VCR.library_hooks.disabled?(:faraday)
        RequestHandler.new(@app, env).handle
      end

      # @private
      class RequestHandler < ::VCR::RequestHandler
        attr_reader :app, :env
        def initialize(app, env)
          @app, @env = app, env
          @has_on_complete_hook = false
        end

        def handle
          # Faraday must be exlusive here in case another library hook is being used.
          # We don't want double recording/double playback.
          VCR.library_hooks.exclusive_hook = :faraday
          super
        ensure
          invoke_after_request_hook(response_for(env)) unless delay_finishing?
        end

      private

        def delay_finishing?
          !!env[:parallel_manager] && @has_on_complete_hook
        end

        def vcr_request
          @vcr_request ||= VCR::Request.new \
            env[:method],
            env[:url].to_s,
            raw_body_from(env[:body]),
            env[:request_headers]
        end

        def raw_body_from(body)
          return body unless body.respond_to?(:read)

          body.read.tap do |b|
            body.rewind if body.respond_to?(:rewind)
          end
        end

        def response_for(env)
          response = env[:response]
          return nil unless response

          VCR::Response.new(
            VCR::ResponseStatus.new(response.status, nil),
            response.headers,
            raw_body_from(response.body),
            nil
          )
        end

        def on_ignored_request
          app.call(env)
        end

        def on_stubbed_by_vcr_request
          headers = env[:response_headers] ||= ::Faraday::Utils::Headers.new
          headers.update stubbed_response.headers if stubbed_response.headers
          env.update :status => stubbed_response.status.code, :body => stubbed_response.body

          faraday_response = ::Faraday::Response.new
          faraday_response.finish(env)
          env[:response] = faraday_response
        end

        def on_recordable_request
          @has_on_complete_hook = true
          app.call(env).on_complete do |env|
            VCR.record_http_interaction(VCR::HTTPInteraction.new(vcr_request, response_for(env)))
            invoke_after_request_hook(response_for(env)) if delay_finishing?
          end
        end

        def invoke_after_request_hook(response)
          super
          VCR.library_hooks.exclusive_hook = nil
        end
      end
    end
  end
end
