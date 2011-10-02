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

  Scenario: Responses do not repeat by default
    Given a previously recorded cassette file "cassettes/example.yml" with:
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
            content-length: 
            - "10"
          body: Response 1
          http_version: "1.1"
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
            content-length: 
            - "10"
          body: Response 2
          http_version: "1.1"
      """
    And a file named "playback_repeats.rb" with:
      """ruby
      include_http_adapter_for("net/http")

      require 'vcr'

      VCR.configure do |c|
        c.stub_with :fakeweb
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
    Then it should fail with "Real HTTP connections are disabled"
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
