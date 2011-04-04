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
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      start_sinatra_app(:port => 7777) do
        get('/:path') { ARGV[0] + ' ' + params[:path] }
      end

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :record => :new_episodes) do
        make_http_request(:get, "http://localhost:7777/foo")
        make_http_request(:get, "http://localhost:7777/bar")
      end
      """
    When I run "ruby cassette_format.rb 'Hello'"
    Then the file "cassettes/example.yml" should contain YAML like:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://localhost:7777/foo
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-type: 
            - text/html;charset=utf-8
            content-length: 
            - "9"
          body: Hello foo
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://localhost:7777/bar
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-type: 
            - text/html;charset=utf-8
            content-length: 
            - "9"
          body: Hello bar
          http_version: "1.1"
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
