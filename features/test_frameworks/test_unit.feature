Feature: Usage with Test::Unit

  To use VCR with Test::Unit, wrap the body of any test method in
  `VCR.use_cassette`.

  Scenario: Use `VCR.use_cassette` in a test
    Given a file named "test/test_server.rb" with:
      """
      require 'vcr_cucumber_helpers'

      start_sinatra_app(:port => 7777) do
        get('/') { "Hello" }
      end
      """
    Given a file named "test/test_helper.rb" with:
      """
      require 'test/unit'
      require 'vcr'

      VCR.config do |c|
        c.stub_with :webmock
        c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
        c.default_cassette_options = { :record => :new_episodes }
      end
      """
    And a file named "test/vcr_example_test.rb" with:
      """
      require 'test_helper'

      class VCRExampleTest < Test::Unit::TestCase
        def test_use_vcr
          VCR.use_cassette('test_unit_example') do
            response = Net::HTTP.get_response('localhost', '/', 7777)
            assert_equal "Hello", response.body
          end
        end
      end
      """
    And the directory "test/fixtures/vcr_cassettes" does not exist
    When I run `ruby -Itest -rtest/test_server test/vcr_example_test.rb`
    Then it should pass with "1 tests, 1 assertions, 0 failures, 0 errors"
    And the file "test/fixtures/vcr_cassettes/test_unit_example.yml" should contain "body: Hello"

    # Run again without starting the sinatra server so the response will be replayed
    When I run `ruby -Itest test/vcr_example_test.rb`
    Then it should pass with "1 tests, 1 assertions, 0 failures, 0 errors"
