Feature: after_http_request hook

  The `after_http_request` hook gets called with each request and response
  just after a request has completed. It can be used for many things:

    * globally logging requests and responses
    * ejecting the current cassette (i.e. if you inserted it in a
      `before_http_request` hook)

  You can also pass one or more "filters" to `after_http_request`, to make
  the hook only be called for some requests. Any object that responds to `#to_proc`
  can be a filter.  Here are some simple examples:

    * `:real?` -- only real requests
    * `:stubbed?` -- only stubbed requests
    * `:ignored?` -- only ignored requests
    * `:recordable?` -- only requests that are being recorded
    * `lambda { |req| URI(req.uri).host == 'amazon.com' }` -- only requests to amazon.com.

  Scenario Outline: log all requests and responses using after_http_request hook
    Given a file named "after_http_request.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      $server = start_sinatra_app do
        get('/foo') { "Hello World (foo)" }
        get('/bar') { "Hello World (bar)" }
      end

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
        c.ignore_localhost = true
        c.after_http_request(:ignored?, lambda { |req| req.uri =~ /foo/ }) do |request, response|
          uri = request.uri.sub(/:\d+/, ":7777")
          puts "Response for #{request.method} #{uri}: #{response.body}"
        end
      end

      make_http_request(:get, "http://localhost:#{$server.port}/foo")
      make_http_request(:get, "http://localhost:#{$server.port}/bar")
      """
    When I run `ruby after_http_request.rb`
    Then the output should contain "Response for get http://localhost:7777/foo: Hello World (foo)"
     But the output should not contain "bar"

   Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :webmock  | httpclient            |
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      | c.hook_into :faraday  | faraday (w/ net_http) |

