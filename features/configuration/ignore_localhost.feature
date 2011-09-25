Feature: ignore_localhost

  The `ignore_localhost` configuration option can be used to prevent VCR
  from having any affect on localhost requests.  If set to true, it will
  never record them and always allow them, regardless of the record mode,
  and even outside of a `VCR.use_cassette` block.

  This is particularly useful when you use VCR with Capybara, since
  Capybara starts a localhost server and pings it when you use one of
  its javascript drivers.

  Background:
    Given a file named "sinatra_app.rb" with:
      """ruby
      response_count = 0
      start_sinatra_app(:port => 7777) do
        get('/') { "Response #{response_count += 1}" }
      end
      """

  Scenario Outline: localhost requests are not treated differently by default and when the setting is false
    Given a file named "localhost_not_ignored.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      require 'vcr'

      VCR.configure do |c|
        <additional_config>
        c.cassette_library_dir = 'cassettes'
        c.stub_with <stub_with>
      end

      VCR.use_cassette('localhost') do
        response_body_for(:get, "http://localhost:7777/")
      end

      response_body_for(:get, "http://localhost:7777/")
      """
    When I run `ruby localhost_not_ignored.rb`
    Then it should fail with "Real HTTP connections are disabled"
     And the file "cassettes/localhost.yml" should contain "body: Response 1"

    Examples:
      | stub_with  | http_lib        | additional_config          |
      | :fakeweb   | net/http        |                            |
      | :fakeweb   | net/http        | c.ignore_localhost = false |
      | :webmock   | net/http        |                            |
      | :webmock   | net/http        | c.ignore_localhost = false |
      | :webmock   | httpclient      |                            |
      | :webmock   | httpclient      | c.ignore_localhost = false |
      | :webmock   | curb            |                            |
      | :webmock   | curb            | c.ignore_localhost = false |
      | :webmock   | patron          |                            |
      | :webmock   | patron          | c.ignore_localhost = false |
      | :webmock   | em-http-request |                            |
      | :webmock   | em-http-request | c.ignore_localhost = false |
      | :webmock   | typhoeus        |                            |
      | :webmock   | typhoeus        | c.ignore_localhost = false |
      | :typhoeus  | typhoeus        |                            |
      | :typhoeus  | typhoeus        | c.ignore_localhost = false |
      | :excon     | excon           |                            |
      | :excon     | excon           | c.ignore_localhost = false |

  Scenario Outline: localhost requests are allowed and not recorded when ignore_localhost = true
    Given a file named "ignore_localhost_true.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      require 'vcr'

      VCR.configure do |c|
        c.ignore_localhost = true
        c.cassette_library_dir = 'cassettes'
        c.stub_with <stub_with>
      end

      VCR.use_cassette('localhost') do
        puts response_body_for(:get, "http://localhost:7777/")
      end

      puts response_body_for(:get, "http://localhost:7777/")
      """
    When I run `ruby ignore_localhost_true.rb`
    Then it should pass with:
      """
      Response 1
      Response 2
      """
    And the file "cassettes/localhost.yml" should not exist

    Examples:
      | stub_with  | http_lib        |
      | :fakeweb   | net/http        |
      | :webmock   | net/http        |
      | :webmock   | httpclient      |
      | :webmock   | patron          |
      | :webmock   | curb            |
      | :webmock   | em-http-request |
      | :webmock   | typhoeus        |
      | :typhoeus  | typhoeus        |
      | :excon     | excon           |

