Feature: Rack

  VCR provides a rack middleware that uses a cassette for the duration of
  a request.  Simply provide `VCR::Middleware::Rack` with a block that sets
  the cassette name and options.  You can set these based on the rack env
  if your block accepts two arguments.

  This is useful in a couple different ways:

  - In a rails app, you could use this to log all HTTP API calls made by
    the rails app (using the `:all` record mode).  Of course, this will only
    record HTTP API calls made in the request-response cycle--API calls that
    are offloaded to a background job will not be logged.
  - This can be used as middleware in a simple rack HTTP proxy, to record
    and replay the proxied requests.

  Background:
    Given a file named "remote_server.rb" with:
      """ruby
      request_count = 0
      $server = start_sinatra_app do
        get('/:path') { "Hello #{params[:path]} #{request_count += 1}" }
      end
      """
    And a file named "client.rb" with:
      """ruby
      require 'remote_server'
      require 'proxy_server'
      require 'cgi'

      url = URI.parse("http://localhost:#{$proxy.port}?url=#{CGI.escape("http://localhost:#{$server.port}/foo")}")

      puts "Response 1: #{Net::HTTP.get_response(url).body}"
      puts "Response 2: #{Net::HTTP.get_response(url).body}"
      """
    And the directory "cassettes" does not exist

  Scenario: Use VCR rack middleware to record HTTP responses for a simple rack proxy app
    Given a file named "proxy_server.rb" with:
      """ruby
      require 'vcr'

      $proxy = start_sinatra_app do
        use VCR::Middleware::Rack do |cassette|
          cassette.name    'proxied'
          cassette.options :record => :new_episodes
        end

        get('/') { Net::HTTP.get_response(URI.parse(params[:url])).body }
      end

      VCR.configure do |c|
        c.cassette_library_dir = 'cassettes'
        c.hook_into :webmock
        c.allow_http_connections_when_no_cassette = true
      end
      """
    When I run `ruby client.rb`
    Then the output should contain:
      """
      Response 1: Hello foo 1
      Response 2: Hello foo 1
      """
    And the file "cassettes/proxied.yml" should contain "Hello foo 1"

  Scenario: Set cassette name based on rack request env
    Given a file named "proxy_server.rb" with:
      """ruby
      require 'vcr'

      $proxy = start_sinatra_app do
        use VCR::Middleware::Rack do |cassette, env|
          cassette.name    env['SERVER_NAME']
        end

        get('/') { Net::HTTP.get_response(URI.parse(params[:url])).body }
      end

      VCR.configure do |c|
        c.cassette_library_dir = 'cassettes'
        c.hook_into :webmock
        c.allow_http_connections_when_no_cassette = true
      end
      """
    When I run `ruby client.rb`
    Then the output should contain:
      """
      Response 1: Hello foo 1
      Response 2: Hello foo 1
      """
    And the file "cassettes/localhost.yml" should contain "Hello foo 1"

