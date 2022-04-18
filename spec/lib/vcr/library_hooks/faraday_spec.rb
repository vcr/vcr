require 'spec_helper'
require 'vcr/library_hooks/faraday'

RSpec.describe "Faraday hook" do
  it 'inserts the VCR middleware just before the adapter' do
    conn = Faraday.new(:url => 'http://sushi.com') do |builder|
      builder.request  :url_encoded
      builder.response :logger
      builder.adapter  :net_http
    end

    conn.builder.lock!
    expect(conn.builder.handlers.last.klass).to eq(VCR::Middleware::Faraday)
  end

  it 'handles the case where no adapter is declared' do
    conn = Faraday.new

    conn.builder.lock!
    expect(conn.builder.handlers.last.klass).to eq(VCR::Middleware::Faraday)
  end

  it 'does nothing if the VCR middleware has already been included' do
    conn = Faraday.new(:url => 'http://sushi.com') do |builder|
      builder.use VCR::Middleware::Faraday
    end

    conn.builder.lock!
    expect(conn.builder.handlers).to eq([VCR::Middleware::Faraday])
  end

  it 'gracefully handles the case where there is no explicit HTTP adapter' do
    conn = Faraday.new(:url => 'http://sushi.com') do |builder|
      builder.request  :url_encoded
      builder.response :logger
    end

    conn.builder.lock!
    expect(conn.builder.handlers.map(&:klass)).to eq([
      Faraday::Request::UrlEncoded,
      Faraday::Response::Logger,
      VCR::Middleware::Faraday
    ])
  end

  context 'when using on_data callback' do
    def make_request(on_data: on_data_callback)
      VCR.use_cassette('no_body') do
        conn = Faraday.new(:url => "http://localhost:#{VCR::SinatraApp.port}") do |builder|
          builder.request  :url_encoded
          builder.adapter  :net_http
        end
        conn.get("localhost_test") do |request|
          request.options.on_data = on_data
        end
      end
    end

    let(:on_data_callback) do
      Proc.new do |chunk, overall_received_bytes|
        on_data_capture.push [chunk, overall_received_bytes]
      end
    end

    let(:on_data_capture) { [] }

    it 'records and replays correctly' do
      expect(on_data_capture).to receive(:push).exactly(2).times.with(["Localhost response", 18])

      recorded = make_request on_data: on_data_callback
      played_back = make_request on_data: on_data_callback

      expect(recorded.body).to eq('Localhost response')
      expect(played_back.body).to eq(recorded.body)
    end
  end
end

