Feature: Cassette format

  VCR Cassettes are files that contain all of the information
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

  By default, VCR uses YAML to serialize this data.  You can configure
  VCR to use a different serializer, either on a cassette-by-cassette
  basis, or as a default for all cassettes if you use the `default_cassette_options`.

  VCR supports the following serializers out of the box:

    * `:yaml`--Uses ruby's standard library YAML. This may use psych or syck,
      depending on your ruby installation.
    * `:syck`--Uses syck (the ruby 1.8 YAML engine). This is useful when using
      VCR on a project that must run in environments where psych is not available
      (such as on ruby 1.8), to ensure that syck is always used.
    * `:psych`--Uses psych (the new ruby 1.9 YAML engine). This is useful when
      you want to ensure that psych is always used.
    * `:json`--Uses [multi_json]() to serialize the cassette data as JSON.

  Scenario Outline: Request/Response data is saved to disk as YAML by default
    Given a file named "cassette_yaml.rb" with:
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
    When I run `ruby cassette_yaml.rb 'Hello'`
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

  Scenario: Request/Response data can be saved as JSON
    Given a file named "cassette_json.rb" with:
      """ruby
      include_http_adapter_for("net/http")

      start_sinatra_app(:port => 7777) do
        get('/:path') { ARGV[0] + ' ' + params[:path] }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :serialize_with => :json) do
        make_http_request(:get, "http://localhost:7777/foo")
        make_http_request(:get, "http://localhost:7777/bar")
      end
      """
    When I run `ruby cassette_json.rb 'Hello'`
    Then the file "cassettes/example.json" should contain JSON like:
      """json
      [
        {
          "response": {
            "body": "Hello foo",
            "http_version": null,
            "status": { "code": 200, "message": "OK" },
            "headers": {
              "Date": [ "Thu, 27 Oct 2011 06:16:31 GMT" ],
              "Content-Type": [ "text/html;charset=utf-8" ],
              "Content-Length": [ "9" ],
              "Server": [ "WEBrick/1.3.1 (Ruby/1.8.7/2011-06-30)" ],
              "Connection": [ "Keep-Alive" ]
            }
          },
          "request": {
            "uri": "http://localhost:7777/foo",
            "body": "",
            "method": "get",
            "headers": { }
          }
        },
        {
          "response": {
            "body": "Hello bar",
            "http_version": null,
            "status": { "code": 200, "message": "OK" },
            "headers": {
              "Date": [ "Thu, 27 Oct 2011 06:16:31 GMT" ],
              "Content-Type": [ "text/html;charset=utf-8" ],
              "Content-Length": [ "9" ],
              "Server": [ "WEBrick/1.3.1 (Ruby/1.8.7/2011-06-30)" ],
              "Connection": [ "Keep-Alive" ]
            }
          },
          "request": {
            "uri": "http://localhost:7777/bar",
            "body": "",
            "method": "get",
            "headers": { }
          }
        }
      ]
      """

