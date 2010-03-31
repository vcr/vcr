require 'vcr/extensions/fake_web'

module VCR
  module HttpStubbingAdapters
    class FakeWeb < Base
      class << self
        def http_connections_allowed?
          ::FakeWeb.allow_net_connect?
        end

        def http_connections_allowed=(value)
          ::FakeWeb.allow_net_connect = value
        end

        def stub_requests(recorded_responses)
          requests = Hash.new([])
          recorded_responses.each do |rr|
            requests[[rr.method, rr.uri]] += [rr.response]
          end
          requests.each do |request, responses|
            ::FakeWeb.register_uri(request.first, request.last, responses.map{ |r| { :response => r } })
          end
        end

        def unstub_requests(recorded_responses)
          recorded_responses.each do |rr|
            ::FakeWeb.remove_from_registry(rr.method, rr.uri)
          end
        end

        def request_stubbed?(method, uri)
          ::FakeWeb.registered_uri?(method, uri)
        end

        def request_uri(net_http, request)
          ::FakeWeb.request_uri(net_http, request)
        end
      end
    end
  end
end

if defined?(FakeWeb::NetConnectNotAllowedError)
  module FakeWeb
    class NetConnectNotAllowedError
      def message
        super + '.  You can use VCR to automatically record this request and replay it later with fakeweb.  For more details, see the VCR README at: http://github.com/myronmarston/vcr'
      end
    end
  end
end
