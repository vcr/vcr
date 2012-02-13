Feature: Matching on Method

  Use the `:method` request matcher to match requests on the HTTP method
  (i.e. GET, POST, PUT, DELETE, etc).  You will generally want to use
  this matcher.

  The `:method` matcher is used (along with the `:uri` matcher) by default
  if you do not specify how requests should match.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      http_interactions: 
      - request: 
          method: post
          uri: http://post-request.com/
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
            - "13"
          body: 
            encoding: UTF-8
            string: post response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request: 
          method: get
          uri: http://get-request.com/
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
            - "12"
          body: 
            encoding: UTF-8
            string: get response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

  Scenario Outline: Replay interaction that matches the HTTP method
    And a file named "method_matching.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :match_requests_on => [:method]) do
        puts "Response for GET: " + response_body_for(:get, "http://example.com/")
      end

      VCR.use_cassette('example', :match_requests_on => [:method]) do
        puts "Response for POST: " + response_body_for(:post,  "http://example.com/")
      end
      """
    When I run `ruby method_matching.rb`
    Then it should pass with:
      """
      Response for GET: get response
      Response for POST: post response
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

