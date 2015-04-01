Feature: Cassette format

  VCR Cassettes are files that contain all of the information
  about the requests and corresponding responses in a
  human-readable/editable format.  A cassette contains an array
  of HTTP interactions, each of which has the following:

    - request
      - method
      - uri
      - body
        - encoding
        - string
      - headers
    - response
      - status
        - code
        - message
      - headers
      - body
        - encoding
        - string
      - http version

  By default, VCR uses YAML to serialize this data.  You can configure
  VCR to use a different serializer, either on a cassette-by-cassette
  basis, or as a default for all cassettes if you use the `default_cassette_options`.

  VCR supports the following serializers out of the box:

    - `:yaml`--Uses ruby's standard library YAML. This may use psych or syck,
      depending on your ruby installation.
    - `:syck`--Uses syck (the ruby 1.8 YAML engine). This is useful when using
      VCR on a project that must run in environments where psych is not available
      (such as on ruby 1.8), to ensure that syck is always used.
    - `:psych`--Uses psych (the new ruby 1.9 YAML engine). This is useful when
      you want to ensure that psych is always used.
    - `:json`--Uses [multi_json](https://github.com/intridea/multi_json)
      to serialize the cassette data as JSON.
    - `:compressed`--Wraps the default YAML serializer with Zlib, writing
      compressed cassettes to disk.

  You can also register a custom serializer using:

       VCR.configure do |config|
         config.cassette_serializers[:my_custom_serializer] = my_serializer
       end

  Your serializer must implement the following methods:

    - `file_extension`
    - `serialize(hash)`
    - `deserialize(string)`

  Scenario Outline: Request/Response data is saved to disk as YAML by default
    Given a file named "cassette_yaml.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      if ARGV.any?
        $server = start_sinatra_app do
          get('/:path') { ARGV[0] + ' ' + params[:path] }
        end
      end

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
        c.before_record do |i|
          i.request.uri.sub!(/:\d+/, ':7777')
        end
      end

      VCR.use_cassette('example') do
        make_http_request(:get, "http://localhost:#{$server.port}/foo", nil, 'Accept-Encoding' => 'identity')
        make_http_request(:get, "http://localhost:#{$server.port}/bar", nil, 'Accept-Encoding' => 'identity')
      end
      """
    When I successfully run `ruby cassette_yaml.rb 'Hello'`
    Then the file "cassettes/example.yml" should contain YAML like:
      """
      ---
      http_interactions:
      - request:
          method: get
          uri: http://localhost:7777/foo
          body:
            encoding: UTF-8
            string: ""
          headers:
            Accept-Encoding:
            - identity
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Type:
            - text/html;charset=utf-8
            Content-Length:
            - "9"
          body:
            encoding: UTF-8
            string: Hello foo
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request:
          method: get
          uri: http://localhost:7777/bar
          body:
            encoding: UTF-8
            string: ""
          headers:
            Accept-Encoding:
            - identity
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Type:
            - text/html;charset=utf-8
            Content-Length:
            - "9"
          body:
            encoding: UTF-8
            string: Hello bar
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
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
      | c.hook_into :faraday  | faraday (w/ net_http) |

  Scenario: Request/Response data can be saved as JSON
    Given a file named "cassette_json.rb" with:
      """ruby
      include_http_adapter_for("net/http")

      $server = start_sinatra_app do
        get('/:path') { ARGV[0] + ' ' + params[:path] }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
        c.before_record do |i|
          i.request.uri.sub!(/:\d+/, ':7777')
        end
        c.default_cassette_options = {
          :match_requests_on => [:method, :host, :path]
        }
      end

      VCR.use_cassette('example', :serialize_with => :json) do
        puts response_body_for(:get, "http://localhost:#{$server.port}/foo", nil, 'Accept-Encoding' => 'identity')
        puts response_body_for(:get, "http://localhost:#{$server.port}/bar", nil, 'Accept-Encoding' => 'identity')
      end
      """
    When I run `ruby cassette_json.rb 'Hello'`
    Then the file "cassettes/example.json" should contain JSON like:
      """json
      {
        "http_interactions": [
          {
            "response": {
              "body": {
                "encoding": "UTF-8",
                "string": "Hello foo"
              },
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
              "body": {
                "encoding": "UTF-8",
                "string": ""
              },
              "method": "get",
              "headers": {
                "Accept-Encoding": [ "identity" ]
              }
            },
            "recorded_at": "Tue, 01 Nov 2011 04:58:44 GMT"
          },
          {
            "response": {
              "body": {
                "encoding": "UTF-8",
                "string": "Hello bar"
              },
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
              "body": {
                "encoding": "UTF-8",
                "string": ""
              },
              "method": "get",
              "headers": {
                "Accept-Encoding": [ "identity" ]
              }
            },
            "recorded_at": "Tue, 01 Nov 2011 04:58:44 GMT"
          }
        ],
        "recorded_with": "VCR 2.0.0"
      }
      """
    When I run `ruby cassette_json.rb`
    Then it should pass with:
      """
      Hello foo
      Hello bar
      """

  Scenario: Request/Response data can be saved as compressed YAML
    Given a file named "cassette_compressed.rb" with:
      """ruby
      include_http_adapter_for("net/http")

      $server = start_sinatra_app do
        get('/:path') { ARGV[0] + ' ' + params[:path] }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
        c.before_record do |i|
          i.request.uri.sub!(/:\d+/, ':7777')
        end
        c.default_cassette_options = {
          :match_requests_on => [:method, :host, :path]
        }
      end

      VCR.use_cassette('example', :serialize_with => :compressed) do
        puts response_body_for(:get, "http://localhost:#{$server.port}/foo", nil, 'Accept-Encoding' => 'identity')
        puts response_body_for(:get, "http://localhost:#{$server.port}/bar", nil, 'Accept-Encoding' => 'identity')
      end

      """
    When I run `ruby cassette_compressed.rb 'Hello'`
    Then the file "cassettes/example.gz" should contain compressed YAML like:
      """
      ---
      http_interactions:
      - request:
          method: get
          uri: http://localhost:7777/foo
          body:
            encoding: UTF-8
            string: ""
          headers:
            Accept-Encoding:
            - identity
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Type:
            - text/html;charset=utf-8
            Content-Length:
            - "9"
          body:
            encoding: UTF-8
            string: Hello foo
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request:
          method: get
          uri: http://localhost:7777/bar
          body:
            encoding: UTF-8
            string: ""
          headers:
            Accept-Encoding:
            - identity
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Type:
            - text/html;charset=utf-8
            Content-Length:
            - "9"
          body:
            encoding: UTF-8
            string: Hello bar
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """
    When I run `ruby cassette_compressed.rb`
    Then it should pass with:
      """
      Hello foo
      Hello bar
      """

  Scenario: Request/Response data can be saved using a custom serializer
    Given a file named "cassette_ruby.rb" with:
      """ruby
      include_http_adapter_for("net/http")

      $server = start_sinatra_app do
        get('/:path') { ARGV[0] + ' ' + params[:path] }
      end

      require 'vcr'

      # purely for demonstration purposes; obviously, don't actually
      # use ruby #inspect / #eval for your serialization...
      ruby_serializer = Object.new
      class << ruby_serializer
        def file_extension; "ruby"; end
        def serialize(hash); hash.inspect; end
        def deserialize(string); eval(string); end
      end

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
        c.cassette_serializers[:ruby] = ruby_serializer
        c.before_record do |i|
          i.request.uri.sub!(/:\d+/, ':7777')
        end
        c.default_cassette_options = {
          :match_requests_on => [:method, :host, :path]
        }
      end

      VCR.use_cassette('example', :serialize_with => :ruby) do
        puts response_body_for(:get, "http://localhost:#{$server.port}/foo", nil, 'Accept-Encoding' => 'identity')
        puts response_body_for(:get, "http://localhost:#{$server.port}/bar", nil, 'Accept-Encoding' => 'identity')
      end
      """
    When I run `ruby cassette_ruby.rb 'Hello'`
    Then the file "cassettes/example.ruby" should contain ruby like:
      """
      {"http_interactions"=>
        [{"request"=>
           {"method"=>"get",
            "uri"=>"http://localhost:7777/foo",
            "body"=>{"encoding"=>"UTF-8", "string"=>""},
            "headers"=>{"Accept"=>["*/*"], "Accept-Encoding"=>["identity"], "User-Agent"=>["Ruby"]}},
          "response"=>
           {"status"=>{"code"=>200, "message"=>"OK "},
            "headers"=>
             {"Content-Type"=>["text/html;charset=utf-8"],
              "Content-Length"=>["9"],
              "Connection"=>["Keep-Alive"]},
            "body"=>{"encoding"=>"UTF-8", "string"=>"Hello foo"},
            "http_version"=>nil},
          "recorded_at"=>"Tue, 01 Nov 2011 04:58:44 GMT"},
         {"request"=>
           {"method"=>"get",
            "uri"=>"http://localhost:7777/bar",
            "body"=>{"encoding"=>"UTF-8", "string"=>""},
            "headers"=>{"Accept"=>["*/*"], "Accept-Encoding"=>["identity"], "User-Agent"=>["Ruby"]}},
          "response"=>
           {"status"=>{"code"=>200, "message"=>"OK "},
            "headers"=>
             {"Content-Type"=>["text/html;charset=utf-8"],
              "Content-Length"=>["9"],
              "Connection"=>["Keep-Alive"]},
            "body"=>{"encoding"=>"UTF-8", "string"=>"Hello bar"},
            "http_version"=>nil},
          "recorded_at"=>"Tue, 01 Nov 2011 04:58:44 GMT"}],
       "recorded_with"=>"VCR 2.0.0"}
      """
    When I run `ruby cassette_ruby.rb`
    Then it should pass with:
      """
      Hello foo
      Hello bar
      """
