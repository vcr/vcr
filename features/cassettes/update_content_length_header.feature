Feature: Update content_length header

  When the `:update_content_length_header` option is set to a truthy value,
  VCR will ensure that the `Content-Length` header will have the correct
  value.  This is useful in several situations:

    - When you manually edit the cassette file and change the resonse body
      length.  You can use this option so you don't have to manually calculate
      and update the body length.
    - When you use ERB, the response body length may vary.  This will ensure
      it is always correct.
    - Syck, the default YAML engine for ruby 1.8 (and 1.9, unless you compile
      it to use Psych), has a bug where it sometimes will remove some
      whitespace strings when you serialize them.  This may cause the
      `Content-Length` header to have the wrong value.

  This is especially important when you use a client that checks the
  `Content-Length` header.  Mechanize, for example, will raise an `EOFError`
  when the header value does not match the actual body length.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      http_interactions: 
      - request: 
          method: get
          uri: http://example.com/
          body: 
            encoding: UTF-8
            string: ""
          headers: {}
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Type: 
            - text/html;charset=utf-8
            Content-Length: 
            - "11"
          body: 
            encoding: UTF-8
            string: Hello <modified>
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """
    And a file named "common_stuff.rb" with:
      """ruby
      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'cassettes'
        c.hook_into :webmock
      end

      def make_request_and_print_results
        response = Net::HTTP.get_response('example.com', '/')
        puts "Body length: #{response.body.length}"
        puts "Header value: #{response['Content-Length']}"
      end
      """

  Scenario: Default :update_content_length_header setting
    Given a file named "default.rb" with:
      """ruby
      require 'common_stuff'

      VCR.use_cassette('example') do
        make_request_and_print_results
      end
      """
    When I run `ruby default.rb`
    Then the output should contain:
      """
      Body length: 16
      Header value: 11
      """

  Scenario: :update_content_length_header => false
    Given a file named "false.rb" with:
      """ruby
      require 'common_stuff'

      VCR.use_cassette('example', :update_content_length_header => false) do
        make_request_and_print_results
      end
      """
    When I run `ruby false.rb`
    Then the output should contain:
      """
      Body length: 16
      Header value: 11
      """

  Scenario: :update_content_length_header => true
    Given a file named "true.rb" with:
      """ruby
      require 'common_stuff'

      VCR.use_cassette('example', :update_content_length_header => true) do
        make_request_and_print_results
      end
      """
    When I run `ruby true.rb`
    Then the output should contain:
      """
      Body length: 16
      Header value: 16
      """

