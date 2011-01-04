Feature: :new_episodes

  The `:new_episodes` record mode replays previously recorded
  requests and records new ones.

  Background:
    Given a file named "setup.rb" with:
      """
      require 'vcr_cucumber_helpers'

      start_sinatra_app(:port => 7777) do
        get('/') { 'Hello' }
      end

      require 'vcr'

      VCR.config do |c|
        c.stub_with                :fakeweb
        c.cassette_library_dir     = 'cassettes'
      end
      """
    And a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/foo
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
            - "20"
          body: example.com response
          http_version: "1.1"
      """

  Scenario: Previously recorded responses are replayed
    Given a file named "replay_recorded_response.rb" with:
      """
      require 'setup'

      VCR.use_cassette('example', :record => :new_episodes) do
        response = Net::HTTP.get_response('example.com', '/foo')
        puts "Response: #{response.body}"
      end
      """
    When I run "ruby replay_recorded_response.rb"
    Then it should pass with "Response: example.com response"

  Scenario: New requests get recorded
    Given a file named "record_new_requests.rb" with:
      """
      require 'setup'

      VCR.use_cassette('example', :record => :new_episodes) do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I run "ruby record_new_requests.rb"
    Then it should pass with "Response: Hello"
    And the file "cassettes/example.yml" should contain each of these:
      | body: example.com response |
      | body: Hello                |
