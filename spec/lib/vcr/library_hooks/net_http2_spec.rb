require 'spec_helper'
require 'vcr/library_hooks/net_http2'

RSpec.describe "Net::HTTP/2 hook" do
  it 'records request' do
    recorded, played_back = [1, 2].map do
      VCR.use_cassette('nghttp2', :record => :once) do
        client = NetHttp2::Client.new("http://nghttp2.org")
        response = client.call(:get, '/')

        response.body
      end
    end

    expect(recorded).to eq(played_back)
  end
end
