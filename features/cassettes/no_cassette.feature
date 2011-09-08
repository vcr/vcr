Feature: Error for HTTP request made when no cassette is in use

  VCR is designed to help you remove all HTTP dependencies from your
  test suite.  To assist with this, VCR will cause an exception to be
  raised when an HTTP request is made while there is no cassette in
  use.  The error is helpful to pinpoint where HTTP requests are
  made so you can use a VCR cassette at that point in your code.

  If you want to allow an HTTP request to proceed as normal, you can
  set the `allow_http_connections_when_no_cassette` configuration option
  (see configuration/allow_http_connections_when_no_cassette.feature) or
  you can temporarily turn VCR off:

    - `VCR.turn_off!` => turn VCR off so HTTP requests are allowed.
      Cassette insertions will trigger an error.
    - `VCR.turn_off!(:ignore_cassettes => true)` => turn
      VCR off and ignore cassette insertions (so that no error is raised).
    - `VCR.turn_on!` => turn VCR back on
    - `VCR.turned_off { ... }` => turn VCR off for the duration of the
      provided block.

  Scenario Outline: Error for request when no cassette is in use
    Given a file named "no_cassette_error.rb" with:
      """ruby
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      response_body_for(:get, 'http://example.com/')
      """
    When I run `ruby no_cassette_error.rb`
    Then it should fail with "<error>"
    And the output should contain each of the following:
      | You can use VCR to automatically record this request and replay it later. |
      | no_cassette_error.rb:11                                                   |

    Examples:
      | stub_with  | http_lib        | error                              |
      | :fakeweb   | net/http        | Real HTTP connections are disabled |
      | :webmock   | net/http        | Real HTTP connections are disabled |
      | :webmock   | httpclient      | Real HTTP connections are disabled |
      | :webmock   | curb            | Real HTTP connections are disabled |
      | :webmock   | patron          | Real HTTP connections are disabled |
      | :webmock   | em-http-request | Real HTTP connections are disabled |
      | :typhoeus  | typhoeus        | Real HTTP requests are not allowed |
      | :excon     | excon           | Real HTTP connections are disabled |

  Scenario: Temporarily turn VCR off to allow HTTP requests to procede as normal
    Given a file named "turn_off_vcr.rb" with:
      """ruby
      require 'vcr_cucumber_helpers'

      start_sinatra_app(:port => 7777) do
        get('/') { 'Hello' }
      end

      require 'vcr'

      VCR.config do |c|
        c.stub_with :fakeweb
      end

      def make_request(context)
        puts context
        puts Net::HTTP.get_response('localhost', '/', 7777).body
      rescue => e
        puts "Error: #{e.message}"
      end

      VCR.turned_off do
        make_request "In VCR.turned_off block"
      end

      make_request "Outside of VCR.turned_off block"

      VCR.turn_off!
      make_request "After calling VCR.turn_off!"

      VCR.turn_on!
      make_request "After calling VCR.turn_on!"
      """
    When I run `ruby turn_off_vcr.rb`
    Then the output should contain:
      """
      In VCR.turned_off block
      Hello
      """
    And the output should contain:
      """
      Outside of VCR.turned_off block
      Error: Real HTTP connections are disabled.
      """
    And the output should contain:
      """
      After calling VCR.turn_off!
      Hello
      """
    And the output should contain:
      """
      After calling VCR.turn_on!
      Error: Real HTTP connections are disabled.
      """

  Scenario: Turning VCR off prevents cassettes from being inserted
    Given a file named "turn_off_vcr_and_insert_cassette.rb" with:
      """ruby
      require 'vcr'

      VCR.config do |c|
        c.stub_with :fakeweb
      end

      VCR.turn_off!
      VCR.insert_cassette('example')
      """
    When I run `ruby turn_off_vcr_and_insert_cassette.rb`
    Then it should fail with "VCR is turned off.  You must turn it on before you can insert a cassette."

  Scenario: Turning VCR off with `:ignore_cassettes => true` ignores cassettes
    Given a file named "turn_off_vcr_and_insert_cassette.rb" with:
      """ruby
      require 'vcr_cucumber_helpers'

      start_sinatra_app(:port => 7777) do
        get('/') { 'Hello' }
      end

      require 'vcr'

      VCR.config do |c|
        c.cassette_library_dir = 'cassettes'
        c.stub_with :fakeweb
      end

      VCR.turn_off!(:ignore_cassettes => true)

      VCR.use_cassette('example') do
        response = Net::HTTP.get_response('localhost', '/', 7777).body
        puts "Response: #{response}"
      end
      """
    When I run `ruby turn_off_vcr_and_insert_cassette.rb`
    Then it should pass with "Response: Hello"
     And the file "cassettes/example.yml" should not exist

