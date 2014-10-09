Feature: Automatic Re-recording

  Over time, your cassettes may get out-of-date. APIs change and sites you
  scrape get updated. VCR provides a facility to automatically re-record your
  cassettes. Enable re-recording using the `:re_record_interval` option.

  The value provided should be an interval (expressed in seconds) that
  determines how often VCR will re-record the cassette.  When a cassette
  is used, VCR checks the earliest `recorded_at` timestamp in the cassette;
  if more time than the interval has passed since that timestamp,
  VCR will use the `:all` record mode to cause it be re-recorded.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      http_interactions: 
      - request: 
          method: get
          uri: http://localhost/
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
            - "12"
          body: 
            encoding: UTF-8
            string: Old Response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """
    And a file named "re_record.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { 'New Response' }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :re_record_interval => 7.days, :match_requests_on => [:method, :host, :path]) do
        puts Net::HTTP.get_response('localhost', '/', $server.port).body
      end
      """

  Scenario: Cassette is not re-recorded when not enough time has passed
    Given it is Tue, 07 Nov 2011
    When I run `ruby re_record.rb`
    Then the output should contain "Old Response"
    But the output should not contain "New Response"
    And the file "cassettes/example.yml" should contain "Old Response"
    But the file "cassettes/example.yml" should not contain "New Response"

  Scenario: Cassette is re-recorded when enough time has passed
    Given it is Tue, 09 Nov 2011
    When I run `ruby re_record.rb`
    Then the output should contain "New Response"
    But the output should not contain "Old Response"
    And the file "cassettes/example.yml" should contain "New Response"
    But the file "cassettes/example.yml" should not contain "Old Response"

