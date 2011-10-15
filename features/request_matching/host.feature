Feature: Matching on Host

  Use the `:host` request matcher to match requests on the request host.

  You can use this (alone, or in combination with `:path`) as an
  alternative to `:uri` so that non-deterministic portions of the URI
  are not considered as part of the request matching.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      - request:
          method: post
          uri: http://host1.com/some/long/path
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '14'
          body: host1 response
          http_version: '1.1'
      - request:
          method: post
          uri: http://host2.com/some/other/long/path
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '16'
          body: host2 response
          http_version: '1.1'
      """

  Scenario Outline: Replay interaction that matches the host
    And a file named "host_matching.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :match_requests_on => [:host]) do
        puts "Response for host2: " + response_body_for(:get, "http://host2.com/home")
      end

      VCR.use_cassette('example', :match_requests_on => [:host]) do
        puts "Response for host1: " + response_body_for(:get,  "http://host1.com/about")
      end
      """
    When I run `ruby host_matching.rb`
    Then it should pass with:
      """
      Response for host2: host2 response
      Response for host1: host1 response
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

