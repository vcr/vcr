Feature: Faraday middleware

  VCR provides middleware that can be used with Faraday.  You can use this as
  an alternative to Faraday's built-in test adapter.

  To use VCR with Faraday, you should configure VCR to stub with faraday and
  use the provided middleware.  The middleware should come before the Faraday
  HTTP adapter.  You should provide the middleware with a block where you set
  the cassette name and options.  If your block accepts two arguments, the
  env hash will be yielded, allowing you to dynamically set the cassette name
  and options based on the request environment.

  Background:
    Given a file named "env_setup.rb" with:
      """ruby
      require 'vcr_cucumber_helpers'

      request_count = 0
      start_sinatra_app(:port => 7777) do
        get('/:path') { "Hello #{params[:path]} #{request_count += 1}" }
      end

      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'cassettes'
        c.stub_with :faraday
      end
      """

  Scenario Outline: Use Faraday middleware
    Given a file named "faraday_example.rb" with:
      """ruby
      require 'env_setup'

      conn = Faraday::Connection.new(:url => 'http://localhost:7777') do |builder|
        builder.use VCR::Middleware::Faraday do |cassette|
          cassette.name    'faraday_example'
          cassette.options :record => :new_episodes
        end

        builder.adapter :<adapter>
      end

      puts "Response 1: #{conn.get('/foo').body}"
      puts "Response 2: #{conn.get('/foo').body}"
      """
    When I run `ruby faraday_example.rb`
    Then the output should contain:
      """
      Response 1: Hello foo 1
      Response 2: Hello foo 1
      """
    And the file "cassettes/faraday_example.yml" should contain "body: Hello foo 1"

    Examples:
      | adapter  |
      | net_http |
      | typhoeus |

  Scenario: Set cassette name based on faraday env
    Given a file named "faraday_example.rb" with:
      """ruby
      require 'env_setup'

      conn = Faraday::Connection.new(:url => 'http://localhost:7777') do |builder|
        builder.use VCR::Middleware::Faraday do |cassette, env|
          cassette.name    env[:url].path.sub(/^\//, '')
        end

        builder.adapter :net_http
      end

      puts "Response 1: #{conn.get('/foo').body}"
      puts "Response 2: #{conn.get('/foo').body}"
      puts "Response 3: #{conn.get('/bar').body}"
      puts "Response 4: #{conn.get('/bar').body}"
      """
    When I run `ruby faraday_example.rb`
    Then the output should contain:
      """
      Response 1: Hello foo 1
      Response 2: Hello foo 1
      Response 3: Hello bar 2
      Response 4: Hello bar 2
      """
    And the file "cassettes/foo.yml" should contain "body: Hello foo 1"
    And the file "cassettes/bar.yml" should contain "body: Hello bar 2"
