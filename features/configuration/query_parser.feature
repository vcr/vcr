Feature: query_parser

  By default, VCR will parse query strings using `CGI.parse` from the Ruby
  standard library. This may not be the most optimal or performant library
  available.  You can set the `query_parser` configuration option to use a
  different parser (such as `Rack::Utils.method(:parse_query)`) to decode,
  normalize, and/or provide a comparison object for query strings.

  The configured query parser needs to expose a `.call` method that returns an
  object which is comparable. This instance needs to implement the following
  API:

    * `#==`     => boolean

  Background:
    Given a file named "cassettes/example.yml" with:
      """
      ---
      http_interactions:
      - request:
          method: get
          uri: http://url.example.com/?bravo=2&alpha=1
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
            - "5"
          body:
            encoding: UTF-8
            string: Hello
          http_version: "1.1"
        recorded_at: Tue, 25 Sep 2012 04:58:44 GMT
      recorded_with: VCR 2.2.5
      """

  Scenario: the VCR query parser gets its value from `query_parser`
    Given a file named "query_parser.rb" with:
      """ruby
      require 'vcr'
      require 'rack'

      VCR.configure do |c|
        c.query_parser = lambda { |query| raise query.inspect }
        c.default_cassette_options = {:match_requests_on => [:query]}
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      uri = URI.parse('http://other-url.example.com/?bravo=2&alpha=1')
      VCR.use_cassette('example') do
        puts Net::HTTP.get_response(uri).body
      end
      """
     When I run `ruby query_parser.rb`
     Then it should fail with an error like:
     """
     "alpha=1&bravo=2"
     """


  Scenario: the `query_parser` defaults to the standard library's `CGI.parse`
    Given a file named "query_parser_default.rb" with:
      """ruby
      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.default_cassette_options = {:match_requests_on => [:query]}
        c.cassette_library_dir = 'cassettes'
      end

      uri = URI.parse('http://other-url.example.com/?bravo=2&alpha=1')
      VCR.use_cassette('example') do
        puts Net::HTTP.get_response(uri).body
      end
      """
     When I run `ruby query_parser_default.rb`
     Then it should pass with "Hello"
