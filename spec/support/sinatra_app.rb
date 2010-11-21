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

    def self.port
      server.port
    end

    def self.server
      @server ||= VCR::LocalhostServer.new(new)
    end
  end
end
