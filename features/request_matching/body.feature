Feature: Matching on Body

  Use the `:body` request matcher to match requests on the request body.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      - request:
          method: post
          uri: http://example.net/some/long/path
          body: body1
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '14'
          body: body1 response
          http_version: '1.1'
      - request:
          method: post
          uri: http://example.net/some/long/path
          body: body2
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '14'
          body: body2 response
          http_version: '1.1'
      """

  Scenario Outline: Replay interaction that matches the body
    And a file named "body_matching.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :match_requests_on => [:body]) do
        puts "Response for body2: " + response_body_for(:put, "http://example.com/", "body2")
      end

      VCR.use_cassette('example', :match_requests_on => [:body]) do
        puts "Response for body1: " + response_body_for(:put, "http://example.com/", "body1")
      end
      """
    When I run `ruby body_matching.rb`
    Then it should pass with:
      """
      Response for body2: body2 response
      Response for body1: body1 response
      """

    Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :webmock  | httpclient            |
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :webmock  | patron                |
      | c.hook_into :webmock  | em-http-request       |
      | c.hook_into :webmock  | typhoeus              |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      |                       | faraday (w/ net_http) |
      |                       | faraday (w/ typhoeus) |

