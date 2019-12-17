Feature: :record_on_error

  The `:record_on_error` flag mode will prevent a cassette from being recorded when the code
  that uses the cassette (a test) raises an error (test failure).

  Background:
    Given a file named "setup.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { 'Hello' }
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into                :webmock
        c.cassette_library_dir     = 'cassettes'
      end
      """

  Scenario: Requests are recorded when no error is raised
    Given a file named "record_when_no_error.rb" with:
      """ruby
      require 'setup'

      VCR.use_cassette('example', :record_on_error => false) do
        response = Net::HTTP.get_response('localhost', '/', $server.port)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby record_when_no_error.rb`
    Then it should pass with "Response: Hello"
    And the file "cassettes/example.yml" should contain "Hello"

  Scenario: Requests are not recorded when an error is raised and :record_on_error is set to false
    Given a file named "do_not_record_on_error.rb" with:
      """ruby
      require 'setup'

      VCR.use_cassette('example', :record => :once, :record_on_error => false) do
        Net::HTTP.get_response('localhost', '/', $server.port)
        raise StandardError, 'The example failed'
      end
      """
    When I run `ruby do_not_record_on_error.rb`
    Then it should fail with "The example failed"
    And the file "cassettes/example.yml" should not exist

  Scenario: Requests are recorded when an error is raised and :record_on_error is set to true
    Given a file named "record_on_error.rb" with:
      """ruby
      require 'setup'

      VCR.use_cassette('example', :record => :once, :record_on_error => true) do
        Net::HTTP.get_response('localhost', '/', $server.port)
        raise StandardError, 'The example failed'
      end
      """
    When I run `ruby record_on_error.rb`
    Then it should fail with "The example failed"
    But the file "cassettes/example.yml" should contain "Hello"
