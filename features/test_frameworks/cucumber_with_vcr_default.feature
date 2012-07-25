Feature: Cucumber with vcr by default

  In a cucumber support file (e.g. features/support/vcr.rb), put code like this:

  ``` ruby
  VCR.cucumber_tags do |t|
    t.tag  '~@novcr', :use_scenario_name => true
  end
  ```
  This will use vcr for all scenarios not tagged with @novcr

  @exclude-jruby
  Scenario: Record HTTP interactions in a scenario by tagging it
    Given a file named "lib/server.rb" with:
      """ruby
      if ENV['WITH_SERVER'] == 'true'
        start_sinatra_app(:port => 7777) do
          get('/:path') { "Hello #{params[:path]}" }
        end
      end
      """

    Given a file named "features/support/vcr.rb" with:
      """ruby
      require "lib/server"
      require 'vcr'

      VCR.configure do |c|
        c.hook_into :fakeweb
        c.cassette_library_dir     = 'features/cassettes'
      end

      VCR.cucumber_tags do |t|
        t.tag '~@novcr', :use_scenario_name => true
      end
      """
    And a file named "features/step_definitions/steps.rb" with:
      """ruby
      require 'net/http'

      When /^a request is made to "([^"]*)"$/ do |url|
        @response = Net::HTTP.get_response(URI.parse(url))
      end

      When /^(.*) within a cassette named "([^"]*)"$/ do |step, cassette_name|
        VCR.use_cassette(cassette_name) { When step }
      end

      Then /^the response should be "([^"]*)"$/ do |expected_response|
        @response.body.should == expected_response
      end
      """
    And a file named "features/vcr_example.feature" with:
      """
      Feature: VCR example

        Note: Cucumber treats the pre-amble as part of the feature name. When
        using the :use_scenario_name option, VCR will only use the first line
        of the feature name as the directory for the cassette.

        Scenario: untagged scenario
          When a request is made to "http://localhost:7777/localhost_request_1"
          Then the response should be "Hello localhost_request_1"

        @novcr
        Scenario: tagged scenario
          When a request is made to "http://localhost:7777/allowed" within a cassette named "allowed"
          Then the response should be "Hello allowed"
          When a request is made to "http://localhost:7777/disallowed_1"
      """
    And the directory "features/cassettes" does not exist
    When I run `cucumber WITH_SERVER=true features/vcr_example.feature`
    Then it should fail with "2 scenarios (1 failed, 1 passed)"
    And the output should contain each of the following:
      | An HTTP request has been made that VCR does not know how to handle:               |
      |   GET http://localhost:7777/disallowed_1                                          |
    And the file "features/cassettes/allowed.yml" should contain "Hello allowed"
    And the file "features/cassettes/VCR_example/untagged_scenario.yml" should contain "Hello localhost_request_1"

    # Run again without the server; we'll get the same responses because VCR
    # will replay the recorded responses.
    When I run `cucumber features/vcr_example.feature`
    Then it should fail with "2 scenarios (1 failed, 1 passed)"
    And the output should contain each of the following:
      | An HTTP request has been made that VCR does not know how to handle:               |
      |   GET http://localhost:7777/disallowed_1                                          |
    And the file "features/cassettes/allowed.yml" should contain "Hello allowed"
    And the file "features/cassettes/VCR_example/untagged_scenario.yml" should contain "Hello localhost_request_1"
