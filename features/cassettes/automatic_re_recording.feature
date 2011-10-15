Feature: Automatic Re-recording

  Over time, your cassettes may get out-of-date. APIs change and sites you
  scrape get updated. VCR provides a facility to automatically re-record your
  cassettes. Enable re-recording using the `:re_record_interval` option.

  The value provided should be an interval (expressed in seconds) that
  determines how often VCR will re-record the cassette.  When a cassette
  is used, VCR checks the file modification time; if more time than the
  interval has passed, VCR will use the `:all` record mode to cause it be
  re-recorded.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      - request:
          method: get
          uri: http://localhost:7777/
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '12'
          body: Old Response
          http_version: '1.1'
      """
    And a file named "re_record.rb" with:
      """ruby
      start_sinatra_app(:port => 7777) do
        get('/') { 'New Response' }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :fakeweb
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :re_record_interval => 7.days) do
        puts Net::HTTP.get_response('localhost', '/', 7777).body
      end
      """

  Scenario: Cassette is not re-recorded when not enough time has passed
    Given 6 days have passed since the cassette was recorded
    When I run `ruby re_record.rb`
    Then the output should contain "Old Response"
    But the output should not contain "New Response"
    And the file "cassettes/example.yml" should contain "body: Old Response"
    But the file "cassettes/example.yml" should not contain "body: New Response"

  Scenario: Cassette is re-recorded when enough time has passed
    Given 8 days have passed since the cassette was recorded
    When I run `ruby re_record.rb`
    Then the output should contain "New Response"
    But the output should not contain "Old Response"
    And the file "cassettes/example.yml" should contain "body: New Response"
    But the file "cassettes/example.yml" should not contain "body: Old Response"

