Feature: Ignore Request

  By default, VCR hooks into every request, either allowing it and recording
  it, or playing back a recorded response, or raising an error to force you
  to deal with the new request.  In some situations, you may prefer to have
  VCR ignore some requests.

  VCR provides 3 configuration options to accomplish this:

    * `ignore_request { |req| ... }` will ignore any request for which the
      given block returns true.
    * `ignore_hosts 'foo.com', 'bar.com'` allows you to specify particular
      hosts to ignore.
    * `ignore_localhost = true` is equivalent to `ignore_hosts 'localhost',
      '127.0.0.1', '0.0.0.0'`. It is particularly useful for when you use
      VCR with a javascript-enabled capybara driver, since capybara boots
      your rack app and makes localhost requests to it to check that it has
      booted.

  Ignored requests are not recorded and are always allowed, regardless of
  the record mode, and even outside of a `VCR.use_cassette` block.

  Background:
    Given a file named "sinatra_app.rb" with:
      """ruby
      response_count = 0
      $server = start_sinatra_app do
        get('/') { "Port 7777 Response #{response_count += 1}" }
      end
      """

  @exclude-jruby
  Scenario Outline: ignore requests to a specific port
    Given a file named "ignore_request.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      response_count = 0
      $server_8888 = start_sinatra_app do
        get('/') { "Port 8888 Response #{response_count += 1}" }
      end

      require 'vcr'

      VCR.configure do |c|
        c.ignore_request do |request|
          URI(request.uri).port == $server.port
        end

        c.default_cassette_options = { :serialize_with => :syck }
        c.cassette_library_dir = 'cassettes'
        <configuration>
      end

      VCR.use_cassette('example') do
        puts response_body_for(:get, "http://localhost:#{$server_8888.port}/")
      end

      VCR.use_cassette('example') do
        puts response_body_for(:get, "http://localhost:#{$server.port}/")
      end

      puts response_body_for(:get, "http://localhost:#{$server.port}/")
      puts response_body_for(:get, "http://localhost:#{$server_8888.port}/")
      """
    When I run `ruby ignore_request.rb`
    Then it should fail with an error like:
      """
      An HTTP request has been made that VCR does not know how to handle:
      """
     And the output should contain:
      """
      Port 8888 Response 1
      Port 7777 Response 1
      Port 7777 Response 2
      """
    And the file "cassettes/example.yml" should contain "Port 8888"
    And the file "cassettes/example.yml" should not contain "Port 7777"

    Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :faraday  | faraday (w/ net_http) |

  Scenario Outline: ignored host requests are not recorded and are always allowed
    Given a file named "ignore_hosts.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      require 'vcr'

      VCR.configure do |c|
        c.ignore_hosts '127.0.0.1', 'localhost'
        c.cassette_library_dir = 'cassettes'
        <configuration>
      end

      VCR.use_cassette('example') do
        puts response_body_for(:get, "http://localhost:#{$server.port}/")
      end

      puts response_body_for(:get, "http://localhost:#{$server.port}/")
      """
    When I run `ruby ignore_hosts.rb`
    Then it should pass with:
      """
      Port 7777 Response 1
      Port 7777 Response 2
      """
    And the file "cassettes/example.yml" should not exist

    Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      | c.hook_into :faraday  | faraday (w/ net_http) |

  @exclude-jruby
  Scenario Outline: localhost requests are not treated differently by default
    Given a file named "localhost_not_ignored.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")
      require 'sinatra_app.rb'

      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'cassettes'
        c.default_cassette_options = { :serialize_with => :syck }
        <configuration>
      end

      VCR.use_cassette('localhost') do
        response_body_for(:get, "http://localhost:#{$server.port}/")
      end

      response_body_for(:get, "http://localhost:#{$server.port}/")
      """
    When I run `ruby localhost_not_ignored.rb`
    Then it should fail with "An HTTP request has been made that VCR does not know how to handle"
     And the file "cassettes/localhost.yml" should contain "Port 7777 Response 1"

    Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      | c.hook_into :faraday  | faraday (w/ net_http) |

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
        puts response_body_for(:get, "http://localhost:#{$server.port}/")
      end

      puts response_body_for(:get, "http://localhost:#{$server.port}/")
      """
    When I run `ruby ignore_localhost_true.rb`
    Then it should pass with:
      """
      Port 7777 Response 1
      Port 7777 Response 2
      """
    And the file "cassettes/localhost.yml" should not exist

    Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      | c.hook_into :faraday  | faraday (w/ net_http) |

