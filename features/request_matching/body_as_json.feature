Feature: Matching on Body

  Use the `:body_as_json` request matcher to match requests on the request body where the body is JSON.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      http_interactions:
      - request:
          method: post
          uri: http://example.net/some/long/path
          body:
            encoding: UTF-8
            string: '{ "a" : "1" }'
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - "14"
          body:
            encoding: UTF-8
            string: body1 response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request:
          method: post
          uri: http://example.net/some/long/path
          body:
            encoding: UTF-8
            string: '{ "a" : "1", "b" : "2" }'
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - "14"
          body:
            encoding: UTF-8
            string: body2 response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

  Scenario Outline: Replay interaction that matches the body as JSON
    And a file named "body_as_json_matching.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :match_requests_on => [:body_as_json]) do
        puts "Response for body as json 2: " + response_body_for(:put, "http://example.com/", '{ "a" : "1", "b" : "2" }')
      end

      VCR.use_cassette('example', :match_requests_on => [:body_as_json]) do
        puts "Response for body as json 1: " + response_body_for(:put, "http://example.com/", '{ "a" : "1" }')
      end
      """
    When I run `ruby body_as_json_matching.rb`
    Then it should pass with:
      """
      Response for body as json 2: body2 response
      Response for body as json 1: body1 response
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
      | c.hook_into :faraday  | faraday (w/ net_http) |
      | c.hook_into :faraday  | faraday (w/ typhoeus) |
