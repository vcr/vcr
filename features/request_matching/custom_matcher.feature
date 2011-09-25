Feature: Register and use a custom matcher

  You can register and use a custom request matcher if the built-in
  matches do not meet your needs:

    VCR.configure do |c|
      c.register_request_matcher :my_custom_matcher do |request_1, request_2|
        identical?(request_1, request_2)
      end
    end

    VCR.use_cassette('my_cassete', :match_requests_on => [:my_custom_matcher] do
      make_http_request
    end

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/search?q=foo&timestamp=1316920490
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "12"
          body: foo response
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/search?q=bar&timestamp=1296723437
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "12"
          body: bar response
          http_version: "1.1"
      """

  Scenario Outline: Match the URI on all but the timestamp query parameter
    And a file named "custom_matcher.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'
      require 'addressable/uri'

      VCR.configure do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
        c.register_request_matcher :uri_without_timestamp do |request_1, request_2|
          uri_1, uri_2 = [request_1, request_2].map do |r|
            uri = Addressable::URI.parse(r.uri)
            uri.query_values = uri.query_values.tap { |q| q.delete('timestamp') }
            uri.to_s
          end

          uri_1 == uri_2
        end
      end

      def search_url(q)
        "http://example.com:80/search?q=#{q}&timestamp=#{Time.now.to_i}"
      end

      VCR.use_cassette('example', :match_requests_on => [:method, :uri_without_timestamp]) do
        puts "Response for bar: " + response_body_for(:get, search_url("bar"))
      end

      VCR.use_cassette('example', :match_requests_on => [:method, :uri_without_timestamp]) do
        puts "Response for foo: " + response_body_for(:get, search_url("foo"))
      end
      """
    When I run `ruby custom_matcher.rb`
    Then it should pass with:
      """
      Response for bar: bar response
      Response for foo: foo response
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

