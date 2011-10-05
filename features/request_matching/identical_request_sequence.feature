Feature: Identical requests are replayed in sequence

  When a cassette contains multiple HTTP interactions that match a request
  based on the configured `:match_requests_on` setting, the responses are
  sequenced: the first matching request will get the first response,
  the second matching request will get the second response, etc.

  Scenario Outline: identical requests are replayed in sequence
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/foo
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "10"
          body: Response 1
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/foo
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "10"
          body: Response 2
          http_version: "1.1"
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
      | c.stub_with :fakeweb  | net/http              |
      | c.stub_with :webmock  | net/http              |
      | c.stub_with :webmock  | httpclient            |
      | c.stub_with :webmock  | curb                  |
      | c.stub_with :webmock  | patron                |
      | c.stub_with :webmock  | em-http-request       |
      | c.stub_with :webmock  | typhoeus              |
      | c.stub_with :typhoeus | typhoeus              |
      | c.stub_with :excon    | excon                 |
      |                       | faraday (w/ net_http) |
      |                       | faraday (w/ typhoeus) |

