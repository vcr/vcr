Feature: Request matching

  In order to properly replay previously recorded requests, VCR must match new
  HTTP requests to a previously recorded one. By default, it matches on HTTP
  method and URI, since that is usually deterministic and fully identifies the
  resource and action for typical RESTful APIs.

  You can customize how VCR matches requests using the `:match_requests_on` option.
  Specify an array of attributes to match on.  Supported attributes are:

    - `:method` - The HTTP method (i.e. GET, POST, PUT or DELETE) of the request.
    - `:uri` - The full URI of the request.
    - `:host` - The host of the URI. You can use this (alone, or in combination
      with `:path`) as an alternative to `:uri` to cause VCR to match using a regex
      that matches the host.
    - `:path` - The path of the URI. You can use this (alone, or in combination
      with `:host`) as an alternative to `:uri` to cause VCR to match using a regex
      that matches the path.
    - `:body` - The body of the request. (Unsupported when you use FakeWeb.)
    - `:headers` - The request headers. (Unsupported when you use FakeWeb.)

  Alternately, you can manually edit a cassette and change a URI to the YAML
  of a regular expression.

  When a cassette contains multiple HTTP interactions containing identical
  match attributes, the responses are sequenced: the first matching request
  will get the first response, the second matching request will get the
  second response, etc.

  Scenario Outline: identical requests rotate through different matching responses
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
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :record => :none) do
        puts response_body_for(:get, 'http://example.com/foo')
        puts response_body_for(:get, 'http://example.com/foo')
      end
      """
    When I run "ruby rotate_responses.rb"
    Then it should pass with:
      """
      Response 1
      Response 2
      """

    Examples:
      | stub_with  | http_lib        |
      | :fakeweb   | net/http        |
      | :webmock   | net/http        |
      | :webmock   | httpclient      |
      | :webmock   | patron          |
      | :webmock   | curb            |
      | :webmock   | em-http-request |
      | :typhoeus  | typhoeus        |
      | :excon     | excon           |

  Scenario Outline: match on host and path (to ignore query params)
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://bar.com:80/foo?date=2010-11-09
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "16"
          body: bar.com response
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://foo.com:80/bar?date=2010-11-10
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "16"
          body: foo.com response
          http_version: "1.1"
      """
    And a file named "host_path_matching.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :record => :none, :match_requests_on => [:host, :path]) do
        puts response_body_for(:post, "http://foo.com/bar?date=#{Date.today.to_s}")
        puts response_body_for(:put,  "http://bar.com/foo?date=#{Date.today.to_s}")
      end
      """
    When I run "ruby host_path_matching.rb"
    Then it should pass with:
      """
      foo.com response
      bar.com response
      """

    Examples:
      | stub_with  | http_lib        |
      | :fakeweb   | net/http        |
      | :webmock   | net/http        |
      | :webmock   | httpclient      |
      | :webmock   | patron          |
      | :webmock   | curb            |
      | :webmock   | em-http-request |
      | :typhoeus  | typhoeus        |
      | :excon     | excon           |

  Scenario Outline: match on request body
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :post
          uri: http://example.com:80/
          body: a=1
          headers: 
            content-type: 
            - application/x-www-form-urlencoded
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "12"
          body: a=1 response
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :post
          uri: http://example.com:80/
          body: a=2
          headers: 
            content-type: 
            - application/x-www-form-urlencoded
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "12"
          body: a=2 response
          http_version: "1.1"
      """
    And a file named "body_matching.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :record => :none, :match_requests_on => [:method, :uri, :body]) do
        puts response_body_for(:post, "http://example.com/", 'a=2')
        puts response_body_for(:post, "http://example.com/", 'a=1')
      end
      """
    When I run "ruby body_matching.rb"
    Then it should pass with:
      """
      a=2 response
      a=1 response
      """

    Examples:
      | stub_with  | http_lib        |
      | :webmock   | net/http        |
      | :webmock   | httpclient      |
      | :webmock   | patron          |
      | :webmock   | curb            |
      | :webmock   | em-http-request |
      | :typhoeus  | typhoeus        |
      | :excon     | excon           |

  Scenario Outline: match on request headers
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/dashboard
          body: 
          headers: 
            x-user-id: 
            - "17"
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "16"
          body: user 17 response
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/dashboard
          body: 
          headers: 
            x-user-id: 
            - "42"
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "16"
          body: user 42 response
          http_version: "1.1"
      """
    And a file named "header_matching.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :record => :none, :match_requests_on => [:method, :uri, :headers]) do
        puts response_body_for(:get, "http://example.com/dashboard", nil, 'X-User-Id' => '42')
        puts response_body_for(:get, "http://example.com/dashboard", nil, 'X-User-Id' => '17')
      end
      """
    When I run "ruby header_matching.rb"
    Then it should pass with:
      """
      user 42 response
      user 17 response
      """

    Examples:
      | stub_with  | http_lib        |
      | :webmock   | net/http        |
      | :webmock   | httpclient      |
      | :webmock   | patron          |
      | :webmock   | curb            |
      | :webmock   | em-http-request |
      | :typhoeus  | typhoeus        |
      | :excon     | excon           |

  Scenario Outline: Use a regex for the request URI
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: !ruby/regexp /^http:\/\/bar\.com\/foo/
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "16"
          body: bar.com response
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: !ruby/regexp /^http:\/\/foo\.com\/bar/
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "16"
          body: foo.com response
          http_version: "1.1"
      """
    And a file named "uri_regex_matching.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :record => :none) do
        puts response_body_for(:get, "http://foo.com/bar?date=#{Date.today.to_s}")
        puts response_body_for(:get, "http://bar.com/foo?date=#{Date.today.to_s}")
      end
      """
    When I run "ruby uri_regex_matching.rb"
    Then it should pass with:
      """
      foo.com response
      bar.com response
      """

    Examples:
      | stub_with  | http_lib        |
      | :fakeweb   | net/http        |
      | :webmock   | net/http        |
      | :webmock   | httpclient      |
      | :webmock   | patron          |
      | :webmock   | curb            |
      | :webmock   | em-http-request |
      | :typhoeus  | typhoeus        |
      | :excon     | excon           |
