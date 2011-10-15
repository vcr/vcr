Feature: Matching on Headers

  Use the `:headers` request matcher to match requests on the request headers.

  Scenario Outline: Replay interaction that matches the headers
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      - request:
          method: post
          uri: http://example.net/some/long/path
          body: ''
          headers:
            X-User-Id:
            - '1'
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '15'
          body: user 1 response
          http_version: '1.1'
      - request:
          method: post
          uri: http://example.net/some/long/path
          body: ''
          headers:
            X-User-Id:
            - '2'
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '15'
          body: user 2 response
          http_version: '1.1'
      """
    And a file named "header_matching.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :match_requests_on => [:headers]) do
        puts "Response for user 2: " + response_body_for(:get, "http://example.com/", nil, 'X-User-Id' => '2')
      end

      VCR.use_cassette('example', :match_requests_on => [:headers]) do
        puts "Response for user 1: " + response_body_for(:get, "http://example.com/", nil, 'X-User-Id' => '1')
      end
      """
    When I run `ruby header_matching.rb`
    Then it should pass with:
      """
      Response for user 2: user 2 response
      Response for user 1: user 1 response
      """

    Examples:
      | configuration         | http_lib              |
      | c.hook_into :webmock  | httpclient            |
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :webmock  | patron                |
      | c.hook_into :webmock  | em-http-request       |
      | c.hook_into :excon    | excon                 |
      |                       | faraday (w/ net_http) |
      |                       | faraday (w/ typhoeus) |

