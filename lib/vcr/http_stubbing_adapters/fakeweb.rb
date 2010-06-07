require 'vcr/extensions/fake_web'
require 'vcr/extensions/net_http'

module VCR
  module HttpStubbingAdapters
    class FakeWeb < Base
      class << self
        def check_version!
          unless meets_version_requirement?(::FakeWeb::VERSION, '1.2.8')
            raise "You are using FakeWeb #{::FakeWeb::VERSION}.  VCR requires version 1.2.8 or greater."
          end
        end

        def http_connections_allowed?
          ::FakeWeb.allow_net_connect?
        end

        def http_connections_allowed=(value)
          ::FakeWeb.allow_net_connect = value
        end

        def stub_requests(http_interactions)
          requests = Hash.new([])

          http_interactions.each do |i|
            requests[[i.request.method, i.request.uri]] += [i.response]
          end

          requests.each do |request, responses|
            ::FakeWeb.register_uri(request.first, request.last, responses.map{ |r| response_hash(r) })
          end
        end

        def create_stubs_checkpoint(checkpoint_name)
          checkpoints[checkpoint_name] = ::FakeWeb::Registry.instance.uri_map.dup
        end

        def restore_stubs_checkpoint(checkpoint_name)
          ::FakeWeb::Registry.instance.uri_map = checkpoints.delete(checkpoint_name)
        end

        def request_stubbed?(method, uri)
          ::FakeWeb.registered_uri?(method, uri)
        end

        def request_uri(net_http, request)
          ::FakeWeb.request_uri(net_http, request)
        end

        private

        def checkpoints
          @checkpoints ||= {}
        end

        def response_hash(response)
          response.headers.merge(
            :body   => response.body,
            :status => [response.status.code.to_s, response.status.message]
          )
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
