@exclude-18
Feature: Debug Logging

  Use the `debug_logger` option to set an IO-like object that VCR will log
  debug output to. This is a useful way to troubleshoot what VCR is doing.

  The debug logger must respond to `#puts`.

  Scenario: Use the debug logger for troubleshooting
    Given a file named "debug_logger.rb" with:
      """ruby
      if ARGV.include?('--with-server')
        $server = start_sinatra_app do
          get('/') { "Hello World" }
        end
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
        c.debug_logger = File.open(ARGV.first, 'w')
        c.default_cassette_options = {
          :match_requests_on => [:method, :host, :path]
        }
      end

      VCR.use_cassette('example') do
        port = $server ? $server.port : 7777
        Net::HTTP.get_response(URI("http://localhost:#{port}/"))
      end
      """
    When I run `ruby debug_logger.rb record.log --with-server`
    Given that port numbers in "record.log" are normalized to "7777"
    Then the file "record.log" should contain exactly:
      """
      [Cassette: 'example'] Initialized with options: {:record=>:once, :match_requests_on=>[:method, :host, :path], :allow_unused_http_interactions=>true, :serialize_with=>:yaml, :persist_with=>:file_system}
      [webmock] Handling request: [get http://localhost:7777/] (disabled: false)
        [Cassette: 'example'] Initialized HTTPInteractionList with request matchers [:method, :host, :path] and 0 interaction(s): {  }
      [webmock] Identified request type (recordable) for [get http://localhost:7777/]
      [Cassette: 'example'] Recorded HTTP interaction [get http://localhost:7777/] => [200 "Hello World"]

      """
    When I run `ruby debug_logger.rb playback.log`
    Given that port numbers in "playback.log" are normalized to "7777"
    Then the file "playback.log" should contain exactly:
      """
      [Cassette: 'example'] Initialized with options: {:record=>:once, :match_requests_on=>[:method, :host, :path], :allow_unused_http_interactions=>true, :serialize_with=>:yaml, :persist_with=>:file_system}
      [webmock] Handling request: [get http://localhost:7777/] (disabled: false)
        [Cassette: 'example'] Initialized HTTPInteractionList with request matchers [:method, :host, :path] and 1 interaction(s): { [get http://localhost:7777/] => [200 "Hello World"] }
        [Cassette: 'example'] Checking if [get http://localhost:7777/] matches [get http://localhost:7777/] using [:method, :host, :path]
          [Cassette: 'example'] method (matched): current request [get http://localhost:7777/] vs [get http://localhost:7777/]
          [Cassette: 'example'] host (matched): current request [get http://localhost:7777/] vs [get http://localhost:7777/]
          [Cassette: 'example'] path (matched): current request [get http://localhost:7777/] vs [get http://localhost:7777/]
        [Cassette: 'example'] Found matching interaction for [get http://localhost:7777/] at index 0: [200 "Hello World"]
      [webmock] Identified request type (stubbed_by_vcr) for [get http://localhost:7777/]

      """
