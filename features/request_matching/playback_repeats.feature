Feature: Playback repeats

  By default, each response in a cassette can only be matched and played back
  once while the cassette is in use (it can, of course, be re-used in multiple
  tests, each of which should use the cassette separately). Note that this is
  a change from the behavior in VCR 1.x. The old behavior occurred because of
  how FakeWeb and WebMock behave internally and was not intended. Repeats create
  less accurate tests since the real HTTP server may not necessarily return the
  same response when identical requests are made in sequence.

  If you want to allow playback repeats, VCR has a cassette option for this:

      :allow_playback_repeats => true

  @exclude-jruby
  Scenario: Responses do not repeat by default
    Given a previously recorded cassette file "cassettes/example.yml" with:
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
            - "10"
          body: 
            encoding: UTF-8
            string: Response 1
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
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
            - "10"
          body: 
            encoding: UTF-8
            string: Response 2
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """
    And a file named "playback_repeats.rb" with:
      """ruby
      include_http_adapter_for("net/http")

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      puts "== With :allow_playback_repeats =="
      VCR.use_cassette('example', :allow_playback_repeats => true) do
        puts response_body_for(:get, 'http://example.com/foo')
        puts response_body_for(:get, 'http://example.com/foo')
        puts response_body_for(:get, 'http://example.com/foo')
      end

      puts "\n== Without :allow_playback_repeats =="
      VCR.use_cassette('example') do
        puts response_body_for(:get, 'http://example.com/foo')
        puts response_body_for(:get, 'http://example.com/foo')
        puts response_body_for(:get, 'http://example.com/foo')
      end
      """
    When I run `ruby playback_repeats.rb`
    Then it should fail with "An HTTP request has been made that VCR does not know how to handle"
     And the output should contain:
      """
      == With :allow_playback_repeats ==
      Response 1
      Response 2
      Response 2

      == Without :allow_playback_repeats ==
      Response 1
      Response 2
      """
