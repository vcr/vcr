require 'fakeweb'
require 'vcr/extensions/net_http'

module VCR
  module HttpStubbingAdapters
    class FakeWeb < Base
      class << self
        UNSUPPORTED_REQUEST_MATCH_ATTRIBUTES = [:body, :headers].freeze
        LOCALHOST_REGEX = %r|\Ahttps?://((\w+:)?\w+@)?(#{VCR::LOCALHOST_ALIASES.map { |a| Regexp.escape(a) }.join('|')})(:\d+)?/|i

        def check_version!
          unless meets_version_requirement?(::FakeWeb::VERSION, '1.3.0')
            raise "You are using FakeWeb #{::FakeWeb::VERSION}.  VCR requires version 1.3.0 or greater."
          end
        end

        def http_connections_allowed?
          !!::FakeWeb.allow_net_connect?("http://some.url/besides/localhost")
        end

        def http_connections_allowed=(value)
          @http_connections_allowed = value
          update_fakeweb_allow_net_connect
        end

        def stub_requests(http_interactions, match_attributes)
          validate_match_attributes(match_attributes)
          requests = Hash.new { |h,k| h[k] = [] }

          http_interactions.each do |i|
            requests[i.request.matcher(match_attributes)] << i.response
          end

          requests.each do |request_matcher, responses|
            ::FakeWeb.register_uri(
              request_matcher.method || :any,
              request_matcher.uri,
              responses.map{ |r| response_hash(r) }
            )
          end
        end

        def create_stubs_checkpoint(checkpoint_name)
          checkpoints[checkpoint_name] = ::FakeWeb::Registry.instance.uri_map.dup
        end

        def restore_stubs_checkpoint(checkpoint_name)
          ::FakeWeb::Registry.instance.uri_map = checkpoints.delete(checkpoint_name)
        end

        def request_stubbed?(request, match_attributes)
          validate_match_attributes(match_attributes)
          ::FakeWeb.registered_uri?(request.method, request.uri)
        end

        def request_uri(net_http, request)
          ::FakeWeb::Utility.request_uri_as_string(net_http, request)
        end

        def ignore_localhost=(value)
          @ignore_localhost = value
          update_fakeweb_allow_net_connect
        end

        def ignore_localhost?
          @ignore_localhost
        end

        private

        def update_fakeweb_allow_net_connect
          ::FakeWeb.allow_net_connect = if @http_connections_allowed
            true
          elsif @ignore_localhost
            LOCALHOST_REGEX
          else
            false
          end
        end

        def checkpoints
          @checkpoints ||= {}
        end

        def response_hash(response)
          response.headers.merge(
            :body   => response.body,
            :status => [response.status.code.to_s, response.status.message]
          )
        end

        def validate_match_attributes(match_attributes)
          invalid_attributes = match_attributes & UNSUPPORTED_REQUEST_MATCH_ATTRIBUTES
          if invalid_attributes.size > 0
            raise UnsupportedRequestMatchAttributeError.new("FakeWeb does not support matching requests on #{invalid_attributes.join(' or ')}")
          end
        end
      end
    end
  end
end

if defined?(FakeWeb::NetConnectNotAllowedError)
  module FakeWeb
    class NetConnectNotAllowedError
      def message
        super + ".  You can use VCR to automatically record this request and replay it later.  For more details, see the VCR README at: http://github.com/myronmarston/vcr/tree/v#{VCR.version}"
      end
    end
  end
end
