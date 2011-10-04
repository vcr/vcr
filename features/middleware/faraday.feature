Feature: Faraday middleware

  VCR provides middleware that can be used with Faraday.  You can use this as
  an alternative to Faraday's built-in test adapter.

  To use VCR with Faraday, simply add the VCR middleware to the Faraday
  connection stack.  The middleware should come before the Faraday
  HTTP adapter.

  Scenario Outline: Use Faraday middleware
    Given a file named "faraday_example.rb" with:
      """ruby
      request_count = 0
      start_sinatra_app(:port => 7777) do
        get('/:path') { "Hello #{params[:path]} #{request_count += 1}" }
      end

      require 'faraday'
      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'cassettes'
      end

      conn = Faraday::Connection.new(:url => 'http://localhost:7777') do |builder|
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
    And the file "cassettes/example.yml" should contain "body: Hello foo 1"

    Examples:
      | adapter  |
      | net_http |
      | typhoeus |

