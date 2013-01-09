Feature: URI without param(s)

  A common source of difficulty when using VCR with the default matchers
  are non-deterministic URIs. If the URI changes on every test run (because
  it includes a timestamp parameter, or whatever), the default URI matcher
  will not work well for you.

  You can write a custom matcher to match URIs however you want, but for the
  common need to match on a URI and ignore particular query parameters, VCR
  provides an easier way:

      :match_requests_on => [
        :method,
        VCR.request_matchers.uri_without_param(:timestamp)
      ]

  `uri_without_param` also has a plural alias (i.e. `uri_without_params(:timestamp, :session)`)

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      http_interactions: 
      - request: 
          method: get
          uri: http://example.com/search?q=foo&timestamp=1316920490
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
            string: foo response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request: 
          method: get
          uri: http://example.com/search?q=bar&timestamp=1296723437
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
            string: bar response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

  Scenario: Match the URI on all but the timestamp query parameter
    And a file named "uri_without_param_matcher.rb" with:
      """ruby
      include_http_adapter_for("net/http")

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
        c.default_cassette_options = {
          :match_requests_on => [:method,
            VCR.request_matchers.uri_without_param(:timestamp)]
        }
      end

      def search_uri(q)
        "http://example.com/search?q=#{q}&timestamp=#{Time.now.to_i}"
      end

      VCR.use_cassette('example') do
        puts "Response for bar: " +
             response_body_for(:get, search_uri("bar"))
      end

      VCR.use_cassette('example') do
        puts "Response for foo: " +
             response_body_for(:get, search_uri("foo"))
      end
      """
    When I run `ruby uri_without_param_matcher.rb`
    Then it should pass with:
      """
      Response for bar: bar response
      Response for foo: foo response
      """

