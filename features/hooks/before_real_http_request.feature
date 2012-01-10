Feature: before_real_http_request hook

  The `before_real_http_request` hook gets called with each "real" request
  just before it proceeds. It will not be called for requests that are played-back
  from cassettes, or when real requests are disabled.

  Scenario Outline: log all requests using a before_real_http_request hook
    Given a file named "before_real_http_request.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      start_sinatra_app(:port => 7777) do
        get('/') { "Hello World" }
      end

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
        c.allow_http_connections_when_no_cassette = true
        c.before_real_http_request do |request|
          puts "before real request: #{request.method} #{request.uri}"
        end
      end

      make_http_request(:get, "http://localhost:7777/")
      """
    When I run `ruby before_real_http_request.rb`
    Then it should pass with "before real request: get http://localhost:7777/"

   Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :webmock  | httpclient            |
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      | c.hook_into :faraday  | faraday (w/ net_http) |

