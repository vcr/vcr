Feature: Matching on URI

  Use the `:uri` request matcher to match requests on the request URI.

  The `:uri` matcher is used (along with the `:method` matcher) by default
  if you do not specify how requests should match.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      - request:
          method: post
          uri: http://example.com/foo
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '12'
          body: foo response
          http_version: '1.1'
      - request:
          method: post
          uri: http://example.com/bar
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '12'
          body: bar response
          http_version: '1.1'
      """

  Scenario Outline: Replay interaction that matches the request URI
    And a file named "uri_matching.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :match_requests_on => [:uri]) do
        puts "Response for /bar: " + response_body_for(:get, "http://example.com/bar")
      end

      VCR.use_cassette('example', :match_requests_on => [:uri]) do
        puts "Response for /foo: " + response_body_for(:get,  "http://example.com/foo")
      end
      """
    When I run `ruby uri_matching.rb`
    Then it should pass with:
      """
      Response for /bar: bar response
      Response for /foo: foo response
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

