require 'spec_helper'

describe "WebMock hook", :with_monkey_patches => :webmock do
  after(:each) do
    ::WebMock.reset!
  end

  def disable_real_connections
    ::WebMock.disable_net_connect!
    ::WebMock::NetConnectNotAllowedError
  end

  def enable_real_connections
    ::WebMock.allow_net_connect!
  end

  def directly_stub_request(method, url, response_body)
    ::WebMock.stub_request(method, url).to_return(:body => response_body)
  end

  %w[net/http patron httpclient em-http-request curb typhoeus excon].each do |lib|
    other = []
    other << :status_message_not_exposed if lib == 'excon'
    it_behaves_like 'a hook into an HTTP library', :webmock, lib, *other do
      if lib == 'net/http'
        def normalize_request_headers(headers)
          headers.merge(DEFAULT_REQUEST_HEADERS)
        end
      end
    end
  end
end
