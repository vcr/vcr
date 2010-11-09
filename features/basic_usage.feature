Feature: basic usage

  VCR makes it easy to record HTTP interactions and replay them.  Simply wrap
  a block of code in `VCR.use_cassette`.  The first time you run the code,
  a real HTTP request will be made, and VCR will record it to a cassette YAML file.
  Subsequent runs will replay the response recorded to the cassette.

  VCR currently uses 3 different HTTP stubbing libraries to support 6 different
  HTTP libraries:

    * FakeWeb can be used to stub Net::HTTP.
    * WebMock can be used to stub:
      * Net::HTTP
      * HTTPClient
      * Patron
      * Curb
      * EM HTTP Request
    * Typhoeus can be used to stub itself.

  Scenario Outline: Record and replay an HTTP interaction
    Given a file named "vcr_example.rb" with:
      """
      require 'vcr_cucumber_helpers'

      start_sinatra_app(:port => 7777) do
        get('/') { ARGV[0] }
      end

      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.config do |c|
        c.stub_with :<stub_with>
        c.cassette_library_dir = 'vcr_cassettes'
      end

      VCR.use_cassette('example', :record => :new_episodes) do
        response = make_http_request(:get, "http://localhost:7777/")
        puts "The response body was: #{get_body_string(response)}"
      end
      """
    When I run "ruby vcr_example.rb 'Hello World'"
    Then the output should contain "The response body was: Hello World"
     And the file "vcr_cassettes/example.yml" should contain "body: Hello World"

    When I run "ruby vcr_example.rb 'Goodbye World'"
    Then the output should contain "The response body was: Hello World"
     And the file "vcr_cassettes/example.yml" should contain "body: Hello World"

   Examples:
      | stub_with | http_lib        |
      | fakeweb   | net/http        |
      | webmock   | net/http        |
      | webmock   | httpclient      |
      | webmock   | patron          |
      | webmock   | curb            |
      | webmock   | em-http-request |
      | typhoeus  | typhoeus        |

