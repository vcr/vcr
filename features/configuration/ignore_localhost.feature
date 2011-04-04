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
      """
      require 'vcr_cucumber_helpers'

      response_count = 0
      start_sinatra_app(:port => 7777) do
        get('/') { "Response #{response_count += 1}" }
      end
      """

  Scenario Outline: localhost requests are not treated differently by default and when the setting is false
    Given a file named "localhost_not_ignored.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      require 'vcr'

      VCR.config do |c|
        <additional_config>
        c.cassette_library_dir = 'cassettes'
        c.stub_with <stub_with>
      end

      VCR.use_cassette('localhost', :record => :new_episodes) do
        response_body_for(:get, "http://localhost:7777/")
      end

      response_body_for(:get, "http://localhost:7777/")
      """
    When I run "ruby localhost_not_ignored.rb"
    Then it should fail with "<error>"
     And the file "cassettes/localhost.yml" should contain "body: Response 1"

    Examples:
      | stub_with  | http_lib        | error                              | additional_config          |
      | :fakeweb   | net/http        | Real HTTP connections are disabled |                            |
      | :fakeweb   | net/http        | Real HTTP connections are disabled | c.ignore_localhost = false |
      | :webmock   | net/http        | Real HTTP connections are disabled |                            |
      | :webmock   | net/http        | Real HTTP connections are disabled | c.ignore_localhost = false |
      | :webmock   | httpclient      | Real HTTP connections are disabled |                            |
      | :webmock   | httpclient      | Real HTTP connections are disabled | c.ignore_localhost = false |
      | :webmock   | curb            | Real HTTP connections are disabled |                            |
      | :webmock   | curb            | Real HTTP connections are disabled | c.ignore_localhost = false |
      | :webmock   | patron          | Real HTTP connections are disabled |                            |
      | :webmock   | patron          | Real HTTP connections are disabled | c.ignore_localhost = false |
      | :webmock   | em-http-request | Real HTTP connections are disabled |                            |
      | :webmock   | em-http-request | Real HTTP connections are disabled | c.ignore_localhost = false |
      | :typhoeus  | typhoeus        | Real HTTP requests are not allowed |                            |
      | :typhoeus  | typhoeus        | Real HTTP requests are not allowed | c.ignore_localhost = false |
      | :excon     | excon           | Real HTTP connections are disabled |                            |
      | :excon     | excon           | Real HTTP connections are disabled | c.ignore_localhost = false |

  Scenario Outline: localhost requests are allowed and not recorded when ignore_localhost = true
    Given a file named "ignore_localhost_true.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      require 'vcr'

      VCR.config do |c|
        c.ignore_localhost = true
        c.cassette_library_dir = 'cassettes'
        c.stub_with <stub_with>
      end

      VCR.use_cassette('localhost', :record => :new_episodes) do
        puts response_body_for(:get, "http://localhost:7777/")
      end

      puts response_body_for(:get, "http://localhost:7777/")
      """
    When I run "ruby ignore_localhost_true.rb"
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
      | :typhoeus  | typhoeus        |
      | :excon     | excon           |

