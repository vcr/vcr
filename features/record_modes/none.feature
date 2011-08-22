Feature: :none

  The `:none` record mode will:

    - Replay previously recorded interactions.
    - Cause an error to be raised for any new requests.

  This is useful when your code makes potentially dangerous
  HTTP requests.  The `:none` record mode guarantees that no
  new HTTP requests will be made.

  Background:
    Given a file named "vcr_config.rb" with:
      """
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
            - "5"
          body: Hello
          http_version: "1.1"
      """

  Scenario: Previously recorded responses are replayed
    Given a file named "replay_recorded_response.rb" with:
      """
      require 'vcr_config'

      VCR.use_cassette('example', :record => :none) do
        response = Net::HTTP.get_response('example.com', '/foo')
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby replay_recorded_response.rb`
    Then it should pass with "Response: Hello"

  Scenario: New requests are prevented
    Given a file named "prevent_new_request.rb" with:
      """
      require 'vcr_config'

      VCR.use_cassette('example', :record => :none) do
        Net::HTTP.get_response('example.com', '/bar')
      end
      """
    When I run `ruby prevent_new_request.rb`
    Then it should fail with "Real HTTP connections are disabled. Unregistered request: GET http://example.com/bar"
