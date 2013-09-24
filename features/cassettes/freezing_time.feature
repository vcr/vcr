Feature: Freezing Time

  When dealing with an HTTP API that includes time-based compontents
  in the request (e.g. for signed S3 requests), it can be useful
  on playback to freeze time to what it originally was when the
  cassette was recorded so that the request is always the same
  each time your test is run.

  While VCR doesn't directly support time freezing, it does
  expose `VCR::Cassette#originally_recorded_at`, which you can
  easily use with a library like
  [timecop](https://github.com/travisjeffery/timecop)
  to freeze time.

  Note: `VCR::Cassette#originally_recorded_at` will return `nil`
  when the cassette is recording for the first time, so you'll
  probably want to use an expression like
  `cassette.originally_recorded_at || Time.now` so that it
  will work when recording or when playing back.

  Scenario: Previously recorded responses are replayed
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      http_interactions: 
      - request: 
          method: get
          uri: http://example.com/events/since/2013-09-23T17:00:30Z
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
            string: Some Event
          http_version: "1.1"
        recorded_at: Mon, 23 Sep 2013 17:00:30 GMT
      recorded_with: VCR 2.0.0
      """
    Given a file named "freeze_time.rb" with:
      """ruby
      require 'time'
      require 'timecop'
      require 'vcr'

      VCR.configure do |vcr|
        vcr.cassette_library_dir = 'cassettes'
        vcr.hook_into :webmock
      end

      VCR.use_cassette('example') do |cassette|
        Timecop.freeze(cassette.originally_recorded_at || Time.now) do
          path = "/events/since/#{Time.now.getutc.iso8601}"
          response = Net::HTTP.get_response('example.com', path)
          puts "Response: #{response.body}"
        end
      end
      """
    When I run `ruby freeze_time.rb`
    Then it should pass with "Response: Some Event"

