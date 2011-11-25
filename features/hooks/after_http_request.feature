Feature: after_http_request hook

  The `after_http_request` hook gets called with each request and response
  just after a request has completed. It can be used for many things:

    * globally logging requests and responses
    * ejecting the current cassette (i.e. if you inserted it in a
      `before_http_request` hook)

  Scenario Outline: log all requests and responses using after_http_request hook
    Given a file named "after_http_request.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      start_sinatra_app(:port => 7777) do
        get('/') { "Hello World" }
      end

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
        c.ignore_localhost = true
        c.after_http_request do |request, response|
          puts "Response for #{request.method} #{request.uri}: #{response.body}"
        end
      end

      make_http_request(:get, "http://localhost:7777/")
      """
    When I run `ruby after_http_request.rb`
    Then it should pass with "Response for get http://localhost:7777/: Hello World"

   Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :webmock  | httpclient            |
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      | c.hook_into :faraday  | faraday (w/ net_http) |

