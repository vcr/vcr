Feature: :new_episodes

  The `:new_episodes` record mode will:

    - Record new interactions.
    - Replay previously recorded interactions.

  It is similar to the `:once` record mode, but will _always_ record new
  interactions, even if you have an existing recorded one that is similar
  (but not identical, based on the `:match_request_on` option).

  Background:
    Given a file named "setup.rb" with:
      """ruby
      start_sinatra_app(:port => 7777) do
        get('/') { 'Hello' }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into                :fakeweb
        c.cassette_library_dir     = 'cassettes'
      end
      """
    And a previously recorded cassette file "cassettes/example.yml" with:
      """
      ---
      - request:
          method: get
          uri: http://example.com/foo
          body: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Length:
            - '20'
          body: example.com response
          http_version: '1.1'
      """

  Scenario: Previously recorded responses are replayed
    Given a file named "replay_recorded_response.rb" with:
      """ruby
      require 'setup'

      VCR.use_cassette('example', :record => :new_episodes) do
        response = Net::HTTP.get_response('example.com', '/foo')
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby replay_recorded_response.rb`
    Then it should pass with "Response: example.com response"

  Scenario: New requests get recorded
    Given a file named "record_new_requests.rb" with:
      """ruby
      require 'setup'

      VCR.use_cassette('example', :record => :new_episodes) do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby record_new_requests.rb`
    Then it should pass with "Response: Hello"
    And the file "cassettes/example.yml" should contain each of these:
      | body: example.com response |
      | body: Hello                |
