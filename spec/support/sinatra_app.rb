require 'sinatra'

module VCR
  class SinatraApp < ::Sinatra::Base
    get '/' do
      "GET to root"
    end

    get '/localhost_test' do
      "Localhost response"
    end

    get '/foo' do
      "FOO!"
    end

    get '/set-cookie-headers/1' do
      headers 'Set-Cookie' => 'foo'
      'header set'
    end

    get '/set-cookie-headers/2' do
      headers 'Set-Cookie' => %w[ foo bar ]
      'header set'
    end

    def self.port
      server.port
    end

    def self.server
      @server ||= VCR::LocalhostServer.new(new)
    end
  end
end
