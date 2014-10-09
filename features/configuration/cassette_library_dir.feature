Feature: cassette_library_dir

  The `cassette_library_dir` configuration option sets a directory
  where VCR saves each cassette.

  Note: When using Rails, avoid using the `test/fixtures` directory 
  to store the cassettes. Rails treats any YAML file in the fixtures 
  directory as an ActiveRecord fixture.
  This will cause an `ActiveRecord::Fixture::FormatError` to be raised.

  Scenario: cassette_library_dir
    Given a file named "cassette_library_dir.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { "Hello" }
      end

      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'vcr/cassettes'
        c.hook_into :webmock
      end

      VCR.use_cassette('localhost') do
        Net::HTTP.get_response('localhost', '/', $server.port)
      end
      """
     And the directory "vcr/cassettes" does not exist
    When I run `ruby cassette_library_dir.rb`
    Then the file "vcr/cassettes/localhost.yml" should exist
