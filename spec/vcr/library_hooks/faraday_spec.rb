require 'spec_helper'
require 'vcr/library_hooks/faraday'

describe "Faraday hook" do
  it 'inserts the VCR middleware just before the adapter' do
    conn = Faraday.new(:url => 'http://sushi.com') do |builder|
      builder.request  :url_encoded
      builder.response :logger
      builder.adapter  :net_http
    end

    conn.builder.lock!
    expect(conn.builder.handlers.last(2).map(&:klass)).to eq([
      VCR::Middleware::Faraday,
      Faraday::Adapter::NetHttp
    ])
  end

  it 'handles the case where no adapter is declared' do
    conn = Faraday.new

    conn.builder.lock!
    expect(conn.builder.handlers.last(2).map(&:klass)).to eq([
      VCR::Middleware::Faraday,
      Faraday::Adapter::NetHttp
    ])
  end

  it 'does nothing if the VCR middleware has already been included' do
    conn = Faraday.new(:url => 'http://sushi.com') do |builder|
      builder.use VCR::Middleware::Faraday
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end

    conn.builder.lock!
    expect(conn.builder.handlers.map(&:klass)).to eq([
      VCR::Middleware::Faraday,
      Faraday::Response::Logger,
      Faraday::Adapter::NetHttp
    ])
  end

  it 'prints a warning if the faraday connection stack contains a middleware after the HTTP adapter' do
    conn = Faraday.new(:url => 'http://sushi.com') do |builder|
      builder.use Faraday::Adapter::NetHttp
      builder.use Faraday::Response::Logger
    end

    expect(conn.builder).to receive(:warn).with(/Faraday::Response::Logger/)
    conn.builder.lock!
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
end

