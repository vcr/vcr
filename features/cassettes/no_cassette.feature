Feature: Error for HTTP request made when no cassette is in use

  VCR is designed to help you remove all HTTP dependencies from your
  test suite.  To assist with this, VCR will cause an exception to be
  raised when an HTTP request is made while there is no cassette in
  use.  The error is helpful to pinpoint where HTTP requests are
  made so you can use a VCR cassette at that point in your code.

  Scenario Outline: Error for request when no cassette is in use
    Given a file named "no_cassette_error.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      get_response(:get, 'http://example.com/')
      """
    When I run "ruby no_cassette_error.rb"
    Then it should fail with "<error>"
    And the output should contain each of the following:
      | You can use VCR to automatically record this request and replay it later. |
      | from no_cassette_error.rb:11                                              |

    Examples:
      | stub_with  | http_lib        | error                              |
      | :fakeweb   | net/http        | Real HTTP connections are disabled |
      | :webmock   | net/http        | Real HTTP connections are disabled |
      | :webmock   | httpclient      | Real HTTP connections are disabled |
      | :webmock   | curb            | Real HTTP connections are disabled |
      | :webmock   | patron          | Real HTTP connections are disabled |
      | :webmock   | em-http-request | Real HTTP connections are disabled |
      | :typhoeus  | typhoeus        | Real HTTP requests are not allowed |
