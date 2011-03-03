Feature: Allow all HTTP connections to be logged by default

  Scenario Outline: Cassettes record and replay as normal
    Given a file named "vcr_setup.rb" with:
      """
      require 'vcr_cucumber_helpers'

      if ARGV.include?('--with-server')
        start_sinatra_app(:port => 7777) do
          get('/') { "Hello" }
        end
      end

      require 'vcr'

      VCR.config do |c|
        c.log_all_to = "application"
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end
      """
    And a file named "record_replay_cassette.rb" with:
      """
      require 'vcr_setup.rb'
      include_http_adapter_for("<http_lib>")

      puts "Response: " + response_body_for(:get, "http://localhost:7777/")
      """
    When I run "ruby record_replay_cassette.rb --with-server"
    Then the output should contain "Response: Hello"
    And the file "cassettes/application.yml" should contain "body: Hello"

    When I run "ruby record_replay_cassette.rb"
    Then the output should contain "Response: Hello"
    
    Examples:
      | stub_with  | http_lib        |
      # | :fakeweb   | net/http        |
      # | :webmock   | net/http        |
      # | :webmock   | httpclient      |
      # | :webmock   | patron          |
      # | :webmock   | curb            |
      # | :webmock   | em-http-request |
      | :typhoeus  | typhoeus        |
