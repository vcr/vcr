@exclude-18 @exclude-1.9.3p327
Feature: around_http_request hook

  The `around_http_request` hook wraps each HTTP request. It can be used
  rather than separate `before_http_request` and `after_http_request` hooks
  to simplify wrapping/transactional logic (such as using a VCR cassette).

  In your block, call `#proceed` on the yielded request to cause it to continue.
  Alternately, you can treat the request as a proc and pass it on to a method that
  expects a block by prefixing it with an ampersand (`&request`).

  Note that `around_http_request` will not work on Ruby 1.8.  It uses a fiber
  under the covers and thus is only available on interpreters that support fibers.
  On 1.8, you can use separate `before_http_request` and `after_http_request` hooks.

  Scenario Outline: globally handle requests using an around_http_request hook
    Given a file named "globally_handle_requests.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      request_count = 0
      $server = start_sinatra_app do
        get('/') { "Response #{request_count += 1 }" }
      end

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
        c.default_cassette_options = { :serialize_with => :syck }
        c.around_http_request do |request|
          VCR.use_cassette('global', :record => :new_episodes, &request)
        end
      end

      puts "Response for request 1: " + response_body_for(:get, "http://localhost:#{$server.port}/")
      puts "Response for request 2: " + response_body_for(:get, "http://localhost:#{$server.port}/")
      """
    When I run `ruby globally_handle_requests.rb`
    Then it should pass with:
      """
      Response for request 1: Response 1
      Response for request 2: Response 1
      """
    And the file "cassettes/global.yml" should contain "Response 1"

   Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :webmock  | httpclient            |
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      | c.hook_into :faraday  | faraday (w/ net_http) |

