Feature: Identical requests are replayed in sequence

  When a cassette contains multiple HTTP interactions that match a request
  based on the configured `:match_requests_on` setting, the responses are
  sequenced: the first matching request will get the first response,
  the second matching request will get the second response, etc.

  Scenario Outline: identical requests are replayed in sequence
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      - request:
          method: get
          uri: http://example.com/foo
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '10'
          body: Response 1
          http_version: '1.1'
      - request:
          method: get
          uri: http://example.com/foo
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '10'
          body: Response 2
          http_version: '1.1'
      """
    And a file named "rotate_responses.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example') do
        puts response_body_for(:get, 'http://example.com/foo')
        puts response_body_for(:get, 'http://example.com/foo')
      end
      """
    When I run `ruby rotate_responses.rb`
    Then it should pass with:
      """
      Response 1
      Response 2
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

