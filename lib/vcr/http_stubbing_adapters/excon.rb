require 'vcr/util/version_checker'
require 'vcr/request_handler'
require 'excon'

VCR::VersionChecker.new('Excon', Excon::VERSION, '0.6.5', '0.6').check_version!

module VCR
  class HTTPStubbingAdapters
    module Excon
      class RequestHandler < ::VCR::RequestHandler
        attr_reader :params
        def initialize(params)
          @params = params
        end

      private

        def on_stubbed_request
          {
            :body     => stubbed_response.body,
            :headers  => normalized_headers(stubbed_response.headers || {}),
            :status   => stubbed_response.status.code
          }
        end

        def response_from_excon_error(error)
          if error.respond_to?(:response)
            error.response
          elsif error.respond_to?(:socket_error)
            response_from_excon_error(error.socket_error)
          else
            warn "WARNING: VCR could not extract a response from Excon error (#{error.inspect})"
          end
        end

        def perform_real_request
          connection = ::Excon.new(uri)

          response = begin
            connection.request(params.merge(:mock => false))
          rescue ::Excon::Errors::Error => e
            yield response_from_excon_error(e) if block_given?
            raise e
          end

          yield response if block_given?

          response.attributes
        end
        alias on_ignored_request perform_real_request

        def on_recordable_request
          perform_real_request do |response|
            unless VCR.http_stubbing_adapters.disabled?(:excon)
              http_interaction = http_interaction_for(response)
              VCR.record_http_interaction(http_interaction)
            end
          end
        end

        def uri
          @uri ||= "#{params[:scheme]}://#{params[:host]}:#{params[:port]}#{params[:path]}#{query}"
        end

        def query
          @query ||= case params[:query]
            when String
              "?#{params[:query]}"
            when Hash
              qry = '?'
              for key, values in params[:query]
                if values.nil?
                  qry << key.to_s << '&'
                else
                  for value in [*values]
                    qry << key.to_s << '=' << CGI.escape(value.to_s) << '&'
                  end
                end
              end
              qry.chop! # remove trailing '&'
            else
              ''
          end
        end

        def http_interaction_for(response)
          VCR::HTTPInteraction.new \
            vcr_request,
            vcr_response(response)
        end

        def vcr_request
          @vcr_request ||= begin
            headers = params[:headers].dup
            headers.delete("Host")

            VCR::Request.new \
              params[:method],
              uri,
              params[:body],
              headers
          end
        end

        def vcr_response(response)
          VCR::Response.new \
            VCR::ResponseStatus.new(response.status, nil),
            response.headers,
            response.body,
            nil
        end

        def normalized_headers(headers)
          normalized = {}
          headers.each do |k, v|
            v = v.join(', ') if v.respond_to?(:join)
            normalized[normalize_header_key(k)] = v
          end
          normalized
        end

        def normalize_header_key(key)
          key.split('-').               # 'user-agent' => %w(user agent)
            each { |w| w.capitalize! }. # => %w(User Agent)
            join('-')
        end

        ::Excon.stub({}) do |params|
          self.new(params).handle
        end
      end

    end
  end
end

Excon.mock = true

