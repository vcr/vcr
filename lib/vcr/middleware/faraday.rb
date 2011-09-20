require 'faraday'

module VCR
  module Middleware
    class Faraday < ::Faraday::Middleware
      include Common

      class HttpConnectionNotAllowedError < StandardError; end

      def call(env)
        VCR::HttpStubbingAdapters::Faraday.exclusively_enabled do
          VCR.use_cassette(*cassette_arguments(env)) do |cassette|
            request = request_for(env)

            if VCR::HttpStubbingAdapters::Faraday.uri_should_be_ignored?(request.uri)
              @app.call(env)
            elsif response = VCR.http_interactions.response_for(request)
              headers = env[:response_headers] ||= ::Faraday::Utils::Headers.new
              headers.update response.headers if response.headers
              env.update :status => response.status.code, :body => response.body

              faraday_response = ::Faraday::Response.new
              faraday_response.finish(env) unless env[:parallel_manager]
              env[:response] = faraday_response
            elsif VCR::HttpStubbingAdapters::Faraday.http_connections_allowed?
              response = @app.call(env)

              # Checking #enabled? isn't strictly needed, but conforms
              # the Faraday adapter to the behavior of the other adapters
              if VCR::HttpStubbingAdapters::Faraday.enabled?
                VCR.record_http_interaction(VCR::HTTPInteraction.new(request, response_for(env)))
              end

              response
            else
              raise HttpConnectionNotAllowedError.new(
                "Real HTTP connections are disabled. Request: #{request.method.inspect} #{request.uri}"
              )
            end
          end
        end
      end

      private

        def request_for(env)
          VCR::Request.new(
            env[:method],
            env[:url].to_s,
            env[:body],
            env[:request_headers]
          )
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
    end
  end
end
