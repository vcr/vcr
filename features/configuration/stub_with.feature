Feature: stub_with configuration option

  The `stub_with` configuration option determines which HTTP stubbing library
  VCR will use.  There are currently 3 supported stubbing libraries which
  support 6 different HTTP libraries:

    * FakeWeb can be used to stub Net::HTTP.
    * WebMock can be used to stub:
      * Net::HTTP
      * HTTPClient
      * Patron
      * Curb
      * EM HTTP Request
    * Typhoeus can be used to stub itself.

  There are some addiitonal trade offs to consider when deciding which
  stubbing library to use:

    * FakeWeb does not allow you to stub a request based on the headers or body.
      Therefore, the `:match_requests_on` option does not support `:body` or
      `:headers` when you use FakeWeb.  Typhoeus and WebMock both support
      matching on `:body` and `:headers`.
    * FakeWeb is currently about 4 times faster than WebMock for stubbing
      Net::HTTP (see benchmarks/http_stubbing_libraries.rb for details).
    * FakeWeb and WebMock both use extensive monkey patching to stub their
      supported HTTP libraries.  Typhoeus provides all the necessary
      stubbing and recording integration points, and no monkey patching
      is required at all.
    * Typhoeus can be used together with either FakeWeb or WebMock.
    * FakeWeb and WebMock cannot both be used.

  Regardless of which library you use, VCR takes care of all of the configuration
  for you.  You should not need to interact directly with FakeWeb, WebMock or the
  stubbing facilities of Typhoeus.  If/when you decide to change stubbing libraries
  (i.e. if you initially use FakeWeb because it's faster but later need the
  additional features of WebMock) you can change the `stub_with` configuration
  option and it'll work with no other changes required.

  Scenario Outline: stub_with loads the given HTTP stubbing library
    Given a file named "vcr_stub_with.rb" with:
      """
      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
      end

      puts "FakeWeb Loaded: #{!!defined?(FakeWeb)}"
      puts "WebMock Loaded: #{!!defined?(WebMock)}"
      puts "Typhoeus Loaded: #{!!defined?(Typhoeus)}"
      """
    When I run "ruby vcr_stub_with.rb"
    Then the output should contain:
      """
      FakeWeb Loaded: <fakeweb_loaded>
      WebMock Loaded: <webmock_loaded>
      Typhoeus Loaded: <typhoeus_loaded>
      """

    Examples:
      | stub_with | fakeweb_loaded | webmock_loaded | typhoeus_loaded |
      | :fakeweb  | true           | false          | false           |
      | :webmock  | false          | true           | false           |
      | :typhoeus | false          | false          | true            |

  Scenario Outline: Record and replay a request using each supported stubbing/http library combination
    Given a file named "stubbing_http_lib_combo.rb" with:
      """
      require 'vcr_cucumber_helpers'
      include_http_adapter_for("<http_lib>")

      start_sinatra_app(:port => 7777) do
        get('/') { ARGV[0] }
      end

      puts "The response for request 1 was: #{response_body_for(:get, "http://localhost:7777/")}"

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'vcr_cassettes'
      end

      VCR.use_cassette('example', :record => :new_episodes) do
        puts "The response for request 2 was: #{response_body_for(:get, "http://localhost:7777/")}"
      end
      """
    When I run "ruby stubbing_http_lib_combo.rb 'Hello World'"
    Then the output should contain each of the following:
      | The response for request 1 was: Hello World |
      | The response for request 2 was: Hello World |
     And the file "vcr_cassettes/example.yml" should contain "body: Hello World"

    When I run "ruby stubbing_http_lib_combo.rb 'Goodbye World'"
    Then the output should contain each of the following:
      | The response for request 1 was: Goodbye World |
      | The response for request 2 was: Hello World   |
     And the file "vcr_cassettes/example.yml" should contain "body: Hello World"

   Examples:
      | stub_with  | http_lib        |
      | :fakeweb   | net/http        |
      | :webmock   | net/http        |
      | :webmock   | httpclient      |
      | :webmock   | patron          |
      | :webmock   | curb            |
      | :webmock   | em-http-request |
      | :typhoeus  | typhoeus        |

  @exclude-jruby
  Scenario Outline: Use Typhoeus in combination with FakeWeb or WebMock
    Given a file named "stub_with_multiple.rb" with:
      """
      require 'vcr_cucumber_helpers'
      require 'typhoeus'

      start_sinatra_app(:port => 7777) do
        get('/:path') { "#{ARGV[0]} #{params[:path]}" }
      end

      def net_http_response
        Net::HTTP.get_response('localhost', '/net_http', 7777).body
      end

      def typhoeus_response
        Typhoeus::Request.get("http://localhost:7777/typhoeus").body
      end

      puts "Net::HTTP 1: #{net_http_response}"
      puts "Typhoeus 1: #{typhoeus_response}"

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>, :typhoeus
        c.cassette_library_dir = 'vcr_cassettes'
      end

      VCR.use_cassette('example', :record => :new_episodes) do
        puts "Net::HTTP 2: #{net_http_response}"
        puts "Typhoeus 2: #{typhoeus_response}"
      end
      """
    When I run "ruby stub_with_multiple.rb 'Hello'"
    Then the output should contain each of the following:
      | Net::HTTP 1: Hello net_http |
      | Typhoeus 1: Hello typhoeus  |
      | Net::HTTP 2: Hello net_http |
      | Typhoeus 2: Hello typhoeus  |
    And the file "vcr_cassettes/example.yml" should contain "body: Hello net_http"
    And the file "vcr_cassettes/example.yml" should contain "body: Hello typhoeus"

    When I run "ruby stub_with_multiple.rb 'Goodbye'"
    Then the output should contain each of the following:
      | Net::HTTP 1: Goodbye net_http |
      | Typhoeus 1: Goodbye typhoeus  |
      | Net::HTTP 2: Hello net_http   |
      | Typhoeus 2: Hello typhoeus    |

  Examples:
    | stub_with |
    | :fakeweb  |
    | :webmock  |
