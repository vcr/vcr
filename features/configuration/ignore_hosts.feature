Feature: ignore_hosts

  The `ignore_hosts` configuration option can be used to prevent VCR
  from having any affect on requests to particular hosts.
  Requests to ignored hosts will not be recorded and will always be
  allowed, regardless of the record mode, and even outside of a
  `VCR.use_cassette` block.

  If you only want to ignore localhost (and its various aliases) you
  may want to use the `ignore_localhost` option instead.

  Background:
    Given a file named "sinatra_app.rb" with:
      """
      require 'vcr_cucumber_helpers'

      response_count = 0
      start_sinatra_app(:port => 7777) do
        get('/') { "Response #{response_count += 1}" }
      end
      """

  Scenario Outline: ignored host requests are not recorded and are always allowed
    Given a file named "ignore_hosts.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      require 'vcr'

      VCR.config do |c|
        c.ignore_hosts '127.0.0.1', 'localhost'
        c.cassette_library_dir = 'cassettes'
        c.stub_with <stub_with>
      end

      VCR.use_cassette('example', :record => :new_episodes) do
        puts response_body_for(:get, "http://localhost:7777/")
      end

      puts response_body_for(:get, "http://localhost:7777/")
      """
    When I run "ruby ignore_hosts.rb"
    Then it should pass with:
      """
      Response 1
      Response 2
      """
    And the file "cassettes/example.yml" should not exist

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

