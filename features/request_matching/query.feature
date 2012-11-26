Feature: Matching on Query string

  Use the `:query` request matcher to match requests on the query string
  portion of the request URI.

  You can use this (alone, or in combination with others) as an
  alternative to `:uri` so that non-deterministic portions of the URI
  are not considered as part of the request matching.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      http_interactions:
      - request:
          method: post
          uri: http://host1.com/query?date=2011-09-01
          body:
            encoding: UTF-8
            string: ""
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - "19"
          body:
            encoding: UTF-8
            string: 2011-09-01 response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request:
          method: post
          uri: http://host1.com/query?date=2011-09-02
          body:
            encoding: UTF-8
            string: ""
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - "19"
          body:
            encoding: UTF-8
            string: 2011-09-02 response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

  Scenario Outline: Replay interaction that matches the query string
    And a file named "query_matching.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.default_cassette_options = { :match_requests_on => [:query] }
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :match_requests_on => [:query]) do
        puts "Response for 2011-09-01 /query: " + response_body_for(:get, "http://example.com/query?date=2011-09-01")
      end

      VCR.use_cassette('example', :match_requests_on => [:query]) do
        puts "Response for 2011-09-02 /query: " + response_body_for(:get,  "http://example.com/query?date=2011-09-02")
      end
      """
    When I run `ruby query_matching.rb`
    Then it should pass with:
      """
      Response for 2011-09-01 /query: 2011-09-01 response
      Response for 2011-09-02 /query: 2011-09-02 response
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

