Feature: hook_into

  The `hook_into` configuration option determines how VCR hooks into the
  HTTP requests to record and replay them.  There are currently 4 valid
  options which support many different HTTP libraries:

    - :webmock can be used to hook into requests from:
      - Net::HTTP
      - HTTPClient
      - Patron
      - Curb (Curl::Easy, but not Curl::Multi)
      - EM HTTP Request
      - Typhoeus (Typhoeus::Hydra, but not Typhoeus::Easy or Typhoeus::Multi)
      - Excon
    - :typhoeus can be used to hook into itself (as long as you use Typhoeus::Hydra,
      but not Typhoeus::Easy or Typhoeus::Multi).
    - :excon can be used to hook into itself.
    - :faraday can be used to hook into itself.
    - :fakeweb (deprecated) can be used to hook into Net::HTTP requests.

  There are some addiitonal trade offs to consider when deciding which
  option to use:

    - WebMock uses extensive monkey patching to hook into supported HTTP 
      libraries.  No monkey patching is used for Typhoeus, Excon or Faraday.
    - Typhoeus, Excon, Faraday can be used together, and with either FakeWeb or WebMock.
    - FakeWeb and WebMock cannot both be used at the same time.

  Regardless of which library you use, VCR takes care of all of the configuration
  for you.  You should not need to interact directly with FakeWeb, WebMock or the
  stubbing facilities of Typhoeus, Excon or Faraday.  If/when you decide to change stubbing
  libraries (i.e. if you initially use FakeWeb because it's faster but later need the
  additional features of WebMock) you can change the `hook_into` configuration
  option and it'll work with no other changes required.

  Scenario Outline: Record and replay a request using each supported hook_into/http library combination
    Given a file named "hook_into_http_lib_combo.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'
      VCR.configure { |c| c.ignore_localhost = true }

      $server = start_sinatra_app do
        get('/') { ARGV[0] }
      end

      puts "The response for request 1 was: #{response_body_for(:get, "http://localhost:#{$server.port}/")}"

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'vcr_cassettes'
        c.ignore_localhost = false
        c.default_cassette_options = { :serialize_with => :syck }
      end

      VCR.use_cassette('example') do
        puts "The response for request 2 was: #{response_body_for(:get, "http://localhost:#{$server.port}/")}"
      end
      """
    When I run `ruby hook_into_http_lib_combo.rb 'Hello World'`
    Then the output should contain each of the following:
      | The response for request 1 was: Hello World |
      | The response for request 2 was: Hello World |
     And the file "vcr_cassettes/example.yml" should contain "Hello World"

    When I run `ruby hook_into_http_lib_combo.rb 'Goodbye World'`
    Then the output should contain each of the following:
      | The response for request 1 was: Goodbye World |
      | The response for request 2 was: Hello World   |
     And the file "vcr_cassettes/example.yml" should contain "Hello World"

   Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :webmock  | httpclient            |
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :webmock  | patron                |
      | c.hook_into :webmock  | em-http-request       |
      | c.hook_into :webmock  | typhoeus              |
      | c.hook_into :webmock  | excon                 |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      | c.hook_into :faraday  | faraday (w/ net_http) |
      | c.hook_into :faraday  | faraday (w/ typhoeus) |

  @exclude-jruby @exclude-18
  Scenario Outline: Use Typhoeus, Excon and Faraday in combination with FakeWeb or WebMock
    Given a file named "hook_into_multiple.rb" with:
      """ruby
      require 'typhoeus'
      require 'excon'
      require 'faraday'
      require 'vcr'
      <extra_require>

      VCR.configure { |c| c.ignore_localhost = true }

      $server = start_sinatra_app do
        get('/:path') { "#{ARGV[0]} #{params[:path]}" }
      end

      def net_http_response
        Net::HTTP.get_response('localhost', '/net_http', $server.port).body
      end

      def typhoeus_response
        Typhoeus::Request.get("http://localhost:#{$server.port}/typhoeus").body
      end

      def excon_response
        Excon.get("http://localhost:#{$server.port}/excon").body
      end

      def faraday_response
        Faraday::Connection.new(:url => "http://localhost:#{$server.port}") do |builder|
          builder.adapter :<faraday_adapter>
        end.get('/faraday').body
      end

      puts "Net::HTTP 1: #{net_http_response}"
      puts "Typhoeus 1: #{typhoeus_response}"
      puts "Excon 1: #{excon_response}"
      puts "Faraday 1: #{faraday_response}"

      VCR.configure do |c|
        c.hook_into <hook_into>, :typhoeus, :excon, :faraday
        c.cassette_library_dir = 'vcr_cassettes'
        c.ignore_localhost = false
      end

      VCR.use_cassette('example') do
        puts "Net::HTTP 2: #{net_http_response}"
        puts "Typhoeus 2: #{typhoeus_response}"
        puts "Excon 2: #{excon_response}"
        puts "Faraday 2: #{faraday_response}"
      end
      """
    When I run `ruby hook_into_multiple.rb 'Hello'`
    Then the output should contain each of the following:
      | Net::HTTP 1: Hello net_http |
      | Typhoeus 1: Hello typhoeus  |
      | Excon 1: Hello excon        |
      | Faraday 1: Hello faraday    |
      | Net::HTTP 2: Hello net_http |
      | Typhoeus 2: Hello typhoeus  |
      | Excon 2: Hello excon        |
      | Faraday 2: Hello faraday    |
    And the cassette "vcr_cassettes/example.yml" should have the following response bodies:
      | Hello net_http |
      | Hello typhoeus |
      | Hello excon    |
      | Hello faraday  |

    When I run `ruby hook_into_multiple.rb 'Goodbye'`
    Then the output should contain each of the following:
      | Net::HTTP 1: Goodbye net_http |
      | Typhoeus 1: Goodbye typhoeus  |
      | Excon 1: Goodbye excon        |
      | Faraday 1: Goodbye faraday    |
      | Net::HTTP 2: Hello net_http   |
      | Typhoeus 2: Hello typhoeus    |
      | Excon 2: Hello excon          |
      | Faraday 2: Hello faraday      |

    Examples:
      | hook_into | faraday_adapter | extra_require                       |
      | :fakeweb  | net_http        |                                     |
      | :webmock  | net_http        |                                     |
      | :fakeweb  | typhoeus        | require 'typhoeus/adapters/faraday' |
      | :webmock  | typhoeus        | require 'typhoeus/adapters/faraday' |
