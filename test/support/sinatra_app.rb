require 'sinatra'

module VCR
  class SinatraApp < ::Sinatra::Base
    disable :protection

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

    get '/redirect-to-root' do
      redirect to('/')
    end

    post '/foo' do
      "FOO!"
    end

    post '/return-request-body' do
      request.body
    end

    get '/set-cookie-headers/1' do
      headers 'Set-Cookie' => 'foo'
      'header set'
    end

    get '/set-cookie-headers/2' do
      headers 'Set-Cookie' => %w[ bar foo ]
      'header set'
    end

    get '/204' do
      status 204
    end

    get '/404_not_200' do
      status 404
      '404 not 200'
    end

    # we use a global counter so that every response is different;
    # this ensures that the test demonstrates that the response
    # is being played back (and not running a 2nd real request)
    $record_and_playback_response_count ||= 0
    get '/record-and-playback' do
      "Response #{$record_and_playback_response_count += 1}"
    end

    post '/record-and-playback' do
      "Response #{$record_and_playback_response_count += 1}"
    end

    @_boot_failed = false

    class << self
      def port
        server.port
      end

      def server
        raise "Sinatra app failed to boot." if @_boot_failed
        @server ||= begin
          VCR::LocalhostServer.new(new)
        rescue
          @_boot_failed = true
          raise
        end
      end

      alias boot server
    end
  end
end
