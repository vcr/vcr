Feature: Matching on Headers

  Use the `:headers` request matcher to match requests on the request headers.

  Scenario Outline: Replay interaction that matches the headers
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      http_interactions: 
      - request: 
          method: post
          uri: http://example.net/some/long/path
          body: 
            encoding: UTF-8
            string: ""
          headers: 
            X-User-Id: 
            - "1"
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Length: 
            - "15"
          body: 
            encoding: UTF-8
            string: user 1 response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request: 
          method: post
          uri: http://example.net/some/long/path
          body: 
            encoding: UTF-8
            string: ""
          headers: 
            X-User-Id: 
            - "2"
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Length: 
            - "15"
          body: 
            encoding: UTF-8
            string: user 2 response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
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
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :webmock  | patron                |
      | c.hook_into :webmock  | em-http-request       |

