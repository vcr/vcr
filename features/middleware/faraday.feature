Feature: Faraday middleware

  VCR provides middleware that can be used with Faraday.  You can use this as
  an alternative to Faraday's built-in test adapter.

  VCR will automatically insert this middleware in the Faraday stack
  when you configure `hook_into :faraday`. However, if you want to control
  where the middleware goes in the faraday stack, you can use it yourself.
  The middleware should come before the Faraday HTTP adapter.

  Note that when you use the middleware directly, you don't need to configure
  `hook_into :faraday`.

  Scenario Outline: Use Faraday middleware
    Given a file named "faraday_example.rb" with:
      """ruby
      request_count = 0
      $server = start_sinatra_app do
        get('/:path') { "Hello #{params[:path]} #{request_count += 1}" }
      end

      require 'faraday'
      require 'vcr'
      <extra_require>

      VCR.configure do |c|
        c.default_cassette_options = { :serialize_with => :syck }
        c.cassette_library_dir = 'cassettes'
      end

      conn = Faraday::Connection.new(:url => "http://localhost:#{$server.port}") do |builder|
        builder.use VCR::Middleware::Faraday
        builder.adapter :<adapter>
      end

      VCR.use_cassette('example') do
        puts "Response 1: #{conn.get('/foo').body}"
      end

      VCR.use_cassette('example') do
        puts "Response 2: #{conn.get('/foo').body}"
      end
      """
    When I run `ruby faraday_example.rb`
    Then the output should contain:
      """
      Response 1: Hello foo 1
      Response 2: Hello foo 1
      """
    And the file "cassettes/example.yml" should contain "Hello foo 1"

    Examples:
      | adapter  | extra_require                       |
      | net_http |                                     |
      | typhoeus | require 'typhoeus/adapters/faraday' |

