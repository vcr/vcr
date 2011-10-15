Feature: Cassette format

  VCR Cassettes are YAML files that contain all of the information
  about the requests and corresponding responses in a
  human-readable/editable format.  A cassette contains an array
  of HTTP interactions, each of which has the following:

    - request
      - method
      - uri
      - body
      - headers
    - response
      - status
        - code
        - message
      - headers
      - body
      - http version

  Scenario Outline: Request/Response data is saved to disk as YAML
    Given a file named "cassette_format.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      start_sinatra_app(:port => 7777) do
        get('/:path') { ARGV[0] + ' ' + params[:path] }
      end

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example') do
        make_http_request(:get, "http://localhost:7777/foo")
        make_http_request(:get, "http://localhost:7777/bar")
      end
      """
    When I run `ruby cassette_format.rb 'Hello'`
    Then the file "cassettes/example.yml" should contain YAML like:
      """
      ---
      - request:
          method: get
          uri: http://localhost:7777/foo
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Type:
            - text/html;charset=utf-8
            Content-Length:
            - '9'
          body: Hello foo
          http_version: '1.1'
      - request:
          method: get
          uri: http://localhost:7777/bar
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Type:
            - text/html;charset=utf-8
            Content-Length:
            - '9'
          body: Hello bar
          http_version: '1.1'
      """

    Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :webmock  | httpclient            |
      | c.hook_into :webmock  | patron                |
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :webmock  | em-http-request       |
      | c.hook_into :webmock  | typhoeus              |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      |                       | faraday (w/ net_http) |

