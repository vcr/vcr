Feature: Allow HTTP connections when no cassette

  Usually, HTTP requests made when no cassette is inserted will [result in an
  error](../cassettes/error-for-http-request-made-when-no-cassette-is-in-use).
  You can set the `allow_http_connections_when_no_cassette` configuration option
  to true to allow requests, if you do not want to use VCR for everything.

  Background:
    Given a file named "vcr_setup.rb" with:
      """ruby
      if ARGV.include?('--with-server')
        $server = start_sinatra_app do
          get('/') { "Hello" }
        end
      end

      require 'vcr'

      VCR.configure do |c|
        c.allow_http_connections_when_no_cassette = true
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
        c.default_cassette_options = {
          :match_requests_on => [:method, :host, :path]
        }
      end
      """
    And the directory "vcr/cassettes" does not exist

  Scenario: Allow HTTP connections when no cassette
    Given a file named "no_cassette.rb" with:
      """ruby
      require 'vcr_setup.rb'

      puts "Response: " + Net::HTTP.get_response('localhost', '/', $server ? $server.port : 0).body
      """
    When I run `ruby no_cassette.rb --with-server`
    Then the output should contain "Response: Hello"

  Scenario: Cassettes record and replay as normal
    Given a file named "record_replay_cassette.rb" with:
      """ruby
      require 'vcr_setup.rb'

      VCR.use_cassette('localhost') do
        puts "Response: " + Net::HTTP.get_response('localhost', '/', $server ? $server.port : 0).body
      end
      """
    When I run `ruby record_replay_cassette.rb --with-server`
    Then the output should contain "Response: Hello"
    And the file "cassettes/localhost.yml" should contain "Hello"

    When I run `ruby record_replay_cassette.rb`
    Then the output should contain "Response: Hello"

