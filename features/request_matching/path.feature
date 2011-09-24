Feature: Matching on Path

  Use the `:path` request matcher to match requests on the path portion
  of the request URI.

  You can use this (alone, or in combination with `:host`) as an
  alternative to `:uri` so that non-deterministic portions of the URI
  are not considered as part of the request matching.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :post
          uri: http://host1.com:80/about?date=2011-09-01
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "14"
          body: about response
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :post
          uri: http://host2.com:80/home?date=2011-09-01
          body:
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "15"
          body: home response
          http_version: "1.1"
      """

  Scenario Outline: Replay interaction that matches the path
    And a file named "path_matching.rb" with:
      """ruby
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :match_requests_on => [:path]) do
        puts "Response for /home: " + response_body_for(:get, "http://example.com/home")
      end

      VCR.use_cassette('example', :match_requests_on => [:path]) do
        puts "Response for /about: " + response_body_for(:get,  "http://example.com/about")
      end
      """
    When I run `ruby path_matching.rb`
    Then it should pass with:
      """
      Response for /home: home response
      Response for /about: about response
      """

    Examples:
      | stub_with  | http_lib        |
      | :fakeweb   | net/http        |
      | :webmock   | net/http        |
      | :webmock   | httpclient      |
      | :webmock   | patron          |
      | :webmock   | curb            |
      | :webmock   | em-http-request |
      | :webmock   | typhoeus        |
      | :typhoeus  | typhoeus        |
      | :excon     | excon           |

