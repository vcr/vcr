Feature: :all

  The `:all` record mode will:

    - Record new interactions.
    - Never replay previously recorded interactions.

  This can be temporarily used to force VCR to re-record
  a cassette (i.e. to ensure the responses are not out of date)
  or can be used when you simply want to log all HTTP requests.

  Background:
    Given a file named "setup.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/')    { 'Hello' }
        get('/foo') { 'Goodbye' }
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
            - "20"
          body: 
            encoding: UTF-8
            string: old response
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

  Scenario: Re-record previously recorded response
    Given a file named "re_record.rb" with:
      """ruby
      require 'setup'

      VCR.use_cassette('example', :record => :all, :match_requests_on => [:method, :host, :path]) do
        response = Net::HTTP.get_response('localhost', '/', $server.port)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby re_record.rb`
    Then it should pass with "Response: Hello"
    And the file "cassettes/example.yml" should contain "Hello"
    But the file "cassettes/example.yml" should not contain "old response"

  Scenario: Record new request
    Given a file named "record_new.rb" with:
      """ruby
      require 'setup'

      VCR.use_cassette('example', :record => :all) do
        response = Net::HTTP.get_response('localhost', '/foo', $server.port)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby record_new.rb`
    Then it should pass with "Response: Goodbye"
    And the file "cassettes/example.yml" should contain each of these:
      | old response |
      | Goodbye      |
