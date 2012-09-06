Feature: Cucumber with Scenario Outline

  vcr :use_scenario_name works with Scenario Outlines

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
        t.tag '@vcr', :use_scenario_name => true
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

        @vcr
        Scenario Outline: scenario outline
          When a request is made to "http://localhost:7777/localhost_request_1"
          Then the response should be "Hello localhost_request_1"
          Examples:
            | key  | value |
            | foo  | bar   |
      """
    And the directory "features/cassettes" does not exist
    When I run `cucumber WITH_SERVER=true features/vcr_example.feature`
    Then it should pass with "1 scenario (1 passed)"
    And the file "features/cassettes/VCR_example/scenario_outline/_foo_bar_.yml" should contain "Hello localhost_request_1"

    # Run again without the server; we'll get the same responses because VCR
    # will replay the recorded responses.
    When I run `cucumber features/vcr_example.feature`
    Then it should pass with "1 scenario (1 passed)"
    And the file "features/cassettes/VCR_example/scenario_outline/_foo_bar_.yml" should contain "Hello localhost_request_1"