Feature: Drop Unused Requests

  If set to true, this cassette option will cause VCR to drop any unused requests
  from the cassette when a cassette is ejected. This is useful for reducing the
  size of cassettes that contain a large number of requests that are not used.

  The option defaults to false (mostly for backwards compatibility).

  Background:
    Given a file named "vcr_config.rb" with:
      """ruby
      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end
      """
    And a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      http_interactions: 
      - request: 
          method: get
          uri: http://example.com/foo
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
            string: Existing Response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

  Scenario: Unused requests are not dropped from the cassette by default
    Given a file named "not_dropped_by_default.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { 'New Response' }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :record => :all) do
        puts Net::HTTP.get_response('localhost', '/', $server.port).body
      end
      """
    When I run `ruby not_dropped_by_default.rb`
    Then the file "cassettes/example.yml" should contain "New Response"
    And the file "cassettes/example.yml" should contain "Existing Response"

  Scenario: Unused requests are dropped from the cassette when the option is set
    Given a file named "drop_unused_requests_set.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { 'New Response' }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example', :record => :all, :drop_unused_requests => true) do
        puts Net::HTTP.get_response('localhost', '/', $server.port).body
      end
      """
    When I run `ruby drop_unused_requests_set.rb`
    Then the file "cassettes/example.yml" should contain "New Response"
    But the file "cassettes/example.yml" should not contain "Existing Response"
