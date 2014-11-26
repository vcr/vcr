Feature: Net::HTTP

  There are many ways to use Net::HTTP.  The scenarios below provide regression
  tests for some Net::HTTP APIs that have not worked properly with VCR and
  FakeWeb or WebMock in the past (but have since been fixed).

  Background:
    Given a file named "vcr_setup.rb" with:
      """ruby
      require 'ostruct'

      if ARGV[0] == '--with-server'
        $server = start_sinatra_app do
          get('/')  { 'VCR works with Net::HTTP gets!' }
          post('/') { 'VCR works with Net::HTTP posts!' }
        end
      else
        $server = OpenStruct(:port => 0)
      end

      require 'vcr'

      VCR.configure do |c|
        c.default_cassette_options = {
          :match_requests_on => [:method, :host, :path]
        }
      end
      """

  Scenario Outline: Calling #post on new Net::HTTP instance
    Given a file named "vcr_net_http.rb" with:
      """ruby
      require 'vcr_setup.rb'

      VCR.configure do |c|
        c.hook_into <hook_into>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('net_http') do
        puts Net::HTTP.new('localhost', $server.port).post('/', '').body
      end
      """
    When I run `ruby vcr_net_http.rb --with-server`
    Then the output should contain "VCR works with Net::HTTP posts!"
    And the file "cassettes/net_http.yml" should contain "VCR works with Net::HTTP posts!"

    When I run `ruby vcr_net_http.rb`
    Then the output should contain "VCR works with Net::HTTP posts!"

    Examples:
      | hook_into |
      | :fakeweb  |
      | :webmock  |

  Scenario Outline: Return from yielded block
    Given a file named "vcr_net_http.rb" with:
      """ruby
      require 'vcr_setup.rb'

      VCR.configure do |c|
        c.hook_into <hook_into>
        c.cassette_library_dir = 'cassettes'
      end

      def perform_request
        Net::HTTP.new('localhost', $server.port).request(Net::HTTP::Get.new('/', {})) do |response|
          return response
        end
      end

      VCR.use_cassette('net_http') do
        puts perform_request.body
      end
      """
    When I run `ruby vcr_net_http.rb --with-server`
    Then the output should contain "VCR works with Net::HTTP gets!"
    And the file "cassettes/net_http.yml" should contain "VCR works with Net::HTTP gets!"

    When I run `ruby vcr_net_http.rb`
    Then the output should contain "VCR works with Net::HTTP gets!"

    Examples:
      | hook_into |
      | :fakeweb  |
      | :webmock  |

  Scenario Outline: Use Net::ReadAdapter to read body in fragments
    Given a file named "vcr_net_http.rb" with:
      """ruby
      require 'vcr_setup.rb'

      VCR.configure do |c|
        c.hook_into <hook_into>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('net_http') do
        body = ''

        Net::HTTP.new('localhost', $server.port).request_get('/') do |response|
          response.read_body { |frag| body << frag }
        end

        puts body
      end
      """
    When I run `ruby vcr_net_http.rb --with-server`
    Then the output should contain "VCR works with Net::HTTP gets!"
    And the file "cassettes/net_http.yml" should contain "VCR works with Net::HTTP gets!"

    When I run `ruby vcr_net_http.rb`
    Then the output should contain "VCR works with Net::HTTP gets!"

    Examples:
      | hook_into |
      | :fakeweb  |
      | :webmock  |

  Scenario Outline: Use open-uri (which is built on top of Net::HTTP and uses a seldom-used Net::HTTP API)
    Given a file named "vcr_net_http.rb" with:
      """ruby
      require 'open-uri'
      require 'vcr_setup.rb'

      VCR.configure do |c|
        c.hook_into <hook_into>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('net_http') do
        puts open("http://localhost:#{$server.port}/").read
      end
      """
    When I run `ruby vcr_net_http.rb --with-server`
    Then the output should contain "VCR works with Net::HTTP gets!"
    And the file "cassettes/net_http.yml" should contain "VCR works with Net::HTTP gets!"

    When I run `ruby vcr_net_http.rb`
    Then the output should contain "VCR works with Net::HTTP gets!"

    Examples:
      | hook_into |
      | :fakeweb  |
      | :webmock  |

    Scenario Outline: Make an HTTPS request
      Given a file named "vcr_https.rb" with:
        """ruby
        require 'vcr'

        VCR.configure do |c|
          c.hook_into <hook_into>
          c.cassette_library_dir = 'cassettes'
        end

        uri = URI("https://gist.githubusercontent.com/myronmarston/fb555cb593f3349d53af/raw/6921dd638337d3f6a51b0e02e7f30e3c414f70d6/vcr_gist")

        VCR.use_cassette('https') do
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          response = http.request_get(uri.path)

          puts response.body
        end
        """
      When I run `ruby vcr_https.rb`
      Then the output should contain "VCR gist"
      And the file "cassettes/https.yml" should contain "VCR gist"

      When I modify the file "cassettes/https.yml" to replace "VCR gist" with "HTTPS replaying works"
      And I run `ruby vcr_https.rb`
      Then the output should contain "HTTPS replaying works"

      Examples:
        | hook_into |
        | :fakeweb  |
        | :webmock  |
