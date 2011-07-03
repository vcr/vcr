require 'sinatra'

module VCR
  class SinatraApp < ::Sinatra::Base
    get '/' do
      "GET to root"
    end

    get '/search' do
      "query: #{params[:q]}"
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
      raise "Sinatra app failed to boot." if @_boot_failed
      @server ||= begin
        VCR::LocalhostServer.new(new)
      rescue
        @_boot_failed = true
        raise
      end
    end
  end
end
