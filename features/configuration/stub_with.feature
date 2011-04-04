Feature: stub_with

  The `stub_with` configuration option determines which HTTP stubbing library
  VCR will use.  There are currently 4 supported stubbing libraries which
  support many different HTTP libraries:

    - FakeWeb can be used to stub Net::HTTP.
    - WebMock can be used to stub:
      - Net::HTTP
      - HTTPClient
      - Patron
      - Curb (Curb::Easy, but not Curb::Multi)
      - EM HTTP Request
    - Typhoeus can be used to stub itself (as long as you use Typhoeus::Hydra,
      but not Typhoeus::Easy or Typhoeus::Multi).
    - Excon can be used to stub itself.
    - Faraday can be used (in combination with the provided Faraday middleware)
      to stub requests made through Faraday (regardless of which Faraday HTTP
      adapter is used).

  There are some addiitonal trade offs to consider when deciding which
  stubbing library to use:

    - FakeWeb does not allow you to stub a request based on the headers or body.
      Therefore, the `:match_requests_on` option does not support `:body` or
      `:headers` when you use FakeWeb.  Typhoeus, WebMock and Faraday both
      support matching on `:body` and `:headers`.
    - FakeWeb is currently about 4 times faster than WebMock for stubbing
      Net::HTTP (see benchmarks/http_stubbing_libraries.rb for details).
    - FakeWeb and WebMock both use extensive monkey patching to stub their
      supported HTTP libraries.  No monkey patching is used for Typhoeus or
      Faraday.
    - FakeWeb and WebMock cannot both be used at the same time.
    - Typhoeus, Excon and Faraday can be used together, and with either
      FakeWeb or WebMock.

  Regardless of which library you use, VCR takes care of all of the configuration
  for you.  You should not need to interact directly with FakeWeb, WebMock or the
  stubbing facilities of Typhoeus, Excon or Faraday.  If/when you decide to change stubbing
  libraries (i.e. if you initially use FakeWeb because it's faster but later need the
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
      puts "Excon Loaded: #{!!defined?(Excon)}"
      """
    When I run "ruby vcr_stub_with.rb"
    Then the output should contain:
      """
      FakeWeb Loaded: <fakeweb_loaded>
      WebMock Loaded: <webmock_loaded>
      Typhoeus Loaded: <typhoeus_loaded>
      Excon Loaded: <excon_loaded>
      """

    Examples:
      | stub_with | fakeweb_loaded | webmock_loaded | typhoeus_loaded | excon_loaded |
      | :fakeweb  | true           | false          | false           | false        |
      | :webmock  | false          | true           | false           | false        |
      | :typhoeus | false          | false          | true            | false        |
      | :excon    | false          | false          | false           | true         |

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
      | :excon     | excon           |

  @exclude-jruby
  Scenario Outline: Use Typhoeus, Excon and Faraday in combination with FakeWeb or WebMock
    Given a file named "stub_with_multiple.rb" with:
      """
      require 'vcr_cucumber_helpers'
      require 'typhoeus'
      require 'excon'

      start_sinatra_app(:port => 7777) do
        get('/:path') { "#{ARGV[0]} #{params[:path]}" }
      end

      def net_http_response
        Net::HTTP.get_response('localhost', '/net_http', 7777).body
      end

      def typhoeus_response
        Typhoeus::Request.get("http://localhost:7777/typhoeus").body
      end

      def excon_response
        Excon.get("http://localhost:7777/excon").body
      end

      def faraday_response
        Faraday::Connection.new(:url => 'http://localhost:7777') do |builder|
          builder.use VCR::Middleware::Faraday do |cassette|
            cassette.name    'example'
            cassette.options :record => :new_episodes
          end

          builder.adapter :<faraday_adapter>
        end.get('/faraday').body
      end

      puts "Net::HTTP 1: #{net_http_response}"
      puts "Typhoeus 1: #{typhoeus_response}"
      puts "Excon 1: #{excon_response}"

      require 'vcr'

      VCR.config do |c|
        c.stub_with <stub_with>, :typhoeus, :excon, :faraday
        c.cassette_library_dir = 'vcr_cassettes'
      end

      VCR.use_cassette('example', :record => :new_episodes) do
        puts "Net::HTTP 2: #{net_http_response}"
        puts "Typhoeus 2: #{typhoeus_response}"
        puts "Excon 2: #{excon_response}"
      end

      puts "Faraday: #{faraday_response}"
      """
    When I run "ruby stub_with_multiple.rb 'Hello'"
    Then the output should contain each of the following:
      | Net::HTTP 1: Hello net_http |
      | Typhoeus 1: Hello typhoeus  |
      | Excon 1: Hello excon        |
      | Net::HTTP 2: Hello net_http |
      | Typhoeus 2: Hello typhoeus  |
      | Excon 2: Hello excon        |
      | Faraday: Hello faraday      |
    And the cassette "vcr_cassettes/example.yml" should have the following response bodies:
      | Hello net_http |
      | Hello typhoeus |
      | Hello excon    |
      | Hello faraday  |

    When I run "ruby stub_with_multiple.rb 'Goodbye'"
    Then the output should contain each of the following:
      | Net::HTTP 1: Goodbye net_http |
      | Typhoeus 1: Goodbye typhoeus  |
      | Excon 1: Goodbye excon        |
      | Net::HTTP 2: Hello net_http   |
      | Typhoeus 2: Hello typhoeus    |
      | Excon 2: Hello excon          |
      | Faraday: Hello faraday        |

    Examples:
      | stub_with | faraday_adapter |
      | :fakeweb  | net_http        |
      | :webmock  | net_http        |
      | :fakeweb  | typhoeus        |
      | :webmock  | typhoeus        |
