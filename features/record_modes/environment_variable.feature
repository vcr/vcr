Feature: Environment variable

  The environment variable named `RECORD` will:

    - Override record mode.

  This can be temporarily used to switch record mode from command line without
  changing code.

  Background:
    Given a file named "setup.rb" with:
      """ruby
      start_sinatra_app(:port => 7777) do
        get('/')    { 'Hello' }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into                :webmock
        c.cassette_library_dir     = 'cassettes'
      end
      """
    And a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      http_interactions:
      - request:
          method: get
          uri: http://localhost:7777/
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
            - "20"
          body:
            encoding: UTF-8
            string: old response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

  Scenario: Override record mode with all and re-record previously recorded response
    Given a file named "override_record_mode_with_all.rb" with:
      """ruby
      require 'setup'

      VCR.use_cassette('example') do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I set the "RECORD" environment variable to "all"
    And I run `ruby override_record_mode_with_all.rb`
    Then it should pass with "Response: Hello"
    And the file "cassettes/example.yml" should contain "Hello"
    But the file "cassettes/example.yml" should not contain "old response"

  Scenario: Override record mode with none and previously recorded responses are replayed
    Given a file named "override_record_mode_with_none.rb" with:
      """ruby
      require 'setup'

      VCR.use_cassette('example', :record => :all) do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I set the "RECORD" environment variable to "none"
    And I run `ruby override_record_mode_with_none.rb`
    Then it should pass with "Response: old response"
