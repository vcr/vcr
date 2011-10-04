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

  Scenario Outline: localhost requests are not treated differently by default
    Given a file named "localhost_not_ignored.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'cassettes'
        <configuration>
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
      | configuration         | http_lib              |
      | c.stub_with :fakeweb  | net/http              |
      | c.stub_with :webmock  | net/http              |
      | c.stub_with :webmock  | httpclient            |
      | c.stub_with :webmock  | curb                  |
      | c.stub_with :webmock  | patron                |
      | c.stub_with :webmock  | em-http-request       |
      | c.stub_with :webmock  | typhoeus              |
      | c.stub_with :typhoeus | typhoeus              |
      | c.stub_with :excon    | excon                 |
      |                       | faraday (w/ net_http) |

  Scenario Outline: localhost requests are allowed and not recorded when ignore_localhost = true
    Given a file named "ignore_localhost_true.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      require 'vcr'

      VCR.configure do |c|
        c.ignore_localhost = true
        c.cassette_library_dir = 'cassettes'
        <configuration>
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
      | configuration         | http_lib              |
      | c.stub_with :fakeweb  | net/http              |
      | c.stub_with :webmock  | net/http              |
      | c.stub_with :webmock  | httpclient            |
      | c.stub_with :webmock  | curb                  |
      | c.stub_with :webmock  | patron                |
      | c.stub_with :webmock  | em-http-request       |
      | c.stub_with :webmock  | typhoeus              |
      | c.stub_with :typhoeus | typhoeus              |
      | c.stub_with :excon    | excon                 |
      |                       | faraday (w/ net_http) |

