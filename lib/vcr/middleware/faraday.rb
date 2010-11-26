require 'faraday'

module VCR
  module Middleware
    class Faraday < ::Faraday::Middleware
      include Common

      class HttpConnectionNotAllowedError < StandardError; end

      # TODO: disable typhoeus/webmock/net_http adapters in here so that we don't record multiple times.
      def call(env)
        VCR.use_cassette(*cassette_arguments(env)) do |cassette|
          request = request_for(env)
          request_matcher = request.matcher(cassette.match_requests_on)

          if VCR::HttpStubbingAdapters::Faraday.ignore_localhost? && VCR::LOCALHOST_ALIASES.include?(URI.parse(request.uri).host)
            @app.call(env)
          elsif response = VCR::HttpStubbingAdapters::Faraday.stubbed_response_for(request_matcher)
            env.update(
              :status           => response.status.code,
              :response_headers => correctly_cased_headers(response.headers),
              :body             => response.body
            )

            env[:response].finish(env)
          elsif VCR::HttpStubbingAdapters::Faraday.http_connections_allowed?
            response = @app.call(env)
            VCR.record_http_interaction(VCR::HTTPInteraction.new(request, response_for(env)))
            response
          else
            raise HttpConnectionNotAllowedError.new(
              "Real HTTP connections are disabled. Request: #{request.method.inspect} #{request.uri}"
            )
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

        def correctly_cased_headers(headers)
          correctly_cased_hash = {}

          headers.each do |key, value|
            key = key.to_s.split('-').map { |segment| segment.capitalize }.join("-")
            correctly_cased_hash[key] = value
          end

          correctly_cased_hash
        end
    end
  end
end
