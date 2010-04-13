require 'webmock'

module VCR
  module HttpStubbingAdapters
    class WebMock < Base
      class << self
        def http_connections_allowed?
          ::WebMock::Config.instance.allow_net_connect
        end

        def http_connections_allowed=(value)
          ::WebMock::Config.instance.allow_net_connect = value
        end

        def stub_requests(recorded_responses)
          requests = Hash.new([])

          # TODO: use the entire request signature, but make it configurable.
          recorded_responses.each do |rr|
            requests[[rr.method, rr.uri]] += [rr.response]
          end

          requests.each do |request, responses|
            ::WebMock.stub_request(request.first, request.last).
              to_return(responses.map{ |r| response_hash(r) })
          end
        end

        def create_stubs_checkpoint(checkpoint_name)
          checkpoints[checkpoint_name] = ::WebMock::RequestRegistry.instance.request_stubs.dup
        end

        def restore_stubs_checkpoint(checkpoint_name)
          ::WebMock::RequestRegistry.instance.request_stubs = checkpoints.delete(checkpoint_name)
        end

        def request_stubbed?(method, uri)
          !!::WebMock.registered_request?(::WebMock::RequestSignature.new(method, uri))
        end

        def request_uri(net_http, request)
          ::WebMock::NetHTTPUtility.request_signature_from_request(net_http, request).uri.to_s
        end

        private

        def response_hash(response)
          {
            :body    => response.body,
            :status  => [response.status.code.to_i, response.status.message],
            :headers => response.headers
          }
        end

        def checkpoints
          @checkpoints ||= {}
        end
      end
    end
  end
end
