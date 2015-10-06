@with-bundler
Feature: Usage with Cucumber

  VCR can be used with cucumber in two basic ways:

    - Use `VCR.use_cassette` in a step definition.
    - Use a `VCR.cucumber_tags` block to tell VCR to use a
      cassette for a tagged scenario.

  In a cucumber support file (e.g. features/support/vcr.rb), put code like this:

  ``` ruby
  VCR.cucumber_tags do |t|
    t.tag  '@tag1'
    t.tags '@tag2', '@tag3'

    t.tag  '@tag3', :cassette => :options
    t.tags '@tag4', '@tag5', :cassette => :options
    t.tag  '@vcr', :use_scenario_name => true
  end
  ```

  VCR will use a cassette named `cucumber_tags/<tag_name>` for scenarios
  with each of these tags (Unless the `:use_scenario_name` option is provided. See below).
  The configured `default_cassette_options` will be used, or you can override specific
  options by passing a hash as the last argument to `#tag` or `#tags`.

  You can also have VCR name your cassettes automatically according to the feature
  and scenario name by providing `:use_scenario_name => true` to `#tag` or `#tags`.
  In this case, the cassette will be named `<feature_name>/<scenario_name>`.
  For scenario outlines, VCR will record one cassette per row, and the cassettes
  will be named `<feature_name>/<scenario_name>/<row_name>`.

  @exclude-jruby
  Scenario: Record HTTP interactions in a scenario by tagging it
    Given a file named "lib/server.rb" with:
      """ruby
      if ENV['WITH_SERVER'] == 'true'
        $server = start_sinatra_app do
          get('/:path') { "Hello #{params[:path]}" }
        end
      end
      """

    Given a file named "features/support/vcr.rb" with:
      """ruby
      require "lib/server"
      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir     = 'features/cassettes'
        c.default_cassette_options = {
          :match_requests_on => [:method, :host, :path]
        }
      end

      VCR.cucumber_tags do |t|
        t.tag  '@localhost_request' # uses default record mode since no options are given
        t.tags '@disallowed_1', '@disallowed_2', :record => :none
        t.tag  '@vcr', :use_scenario_name => true
      end
      """
    And a file named "features/step_definitions/steps.rb" with:
      """ruby
      require 'net/http'

      When /^a request is made to "([^"]*)"$/ do |url|
        uri = URI.parse(url)
        uri.port = $server.port if $server
        @response = Net::HTTP.get_response(uri)
      end

      When /^(.*) within a cassette named "([^"]*)"$/ do |step_name, cassette_name|
        VCR.use_cassette(cassette_name) { step(step_name) }
      end

      Then /^the response should be "([^"]*)"$/ do |expected_response|
        expect(@response.body).to eq(expected_response)
      end
      """
    And a file named "features/vcr_example.feature" with:
      """
      Feature: VCR example

        Note: Cucumber treats the pre-amble as part of the feature name. When
        using the :use_scenario_name option, VCR will only use the first line
        of the feature name as the directory for the cassette.

        @localhost_request
        Scenario: tagged scenario
          When a request is made to "http://localhost:7777/localhost_request_1"
          Then the response should be "Hello localhost_request_1"
          When a request is made to "http://localhost:7777/nested_cassette" within a cassette named "nested_cassette"
          Then the response should be "Hello nested_cassette"
          When a request is made to "http://localhost:7777/localhost_request_2"
          Then the response should be "Hello localhost_request_2"

        @vcr
        Scenario: tagged scenario

        Note: Like the feature pre-amble, Cucumber treats the scenario pre-amble
        as part of the scenario name. When using the :use_scenario_name option,
        VCR will only use the first line of the feature name as the directory
        for the cassette.

          When a request is made to "http://localhost:7777/localhost_request_1"
          Then the response should be "Hello localhost_request_1"

        @vcr
        Scenario Outline: tagged scenario outline
          When a request is made to "http://localhost:7777/localhost_request_1"
          Then the response should be "Hello localhost_request_1"
          Examples:
            | key  | value |
            | foo  | bar   |

        @disallowed_1
        Scenario: tagged scenario
          When a request is made to "http://localhost:7777/allowed" within a cassette named "allowed"
          Then the response should be "Hello allowed"
          When a request is made to "http://localhost:7777/disallowed_1"

        @disallowed_2
        Scenario: tagged scenario
          When a request is made to "http://localhost:7777/disallowed_2"
      """
    And the directory "features/cassettes" does not exist
    When I run `cucumber WITH_SERVER=true features/vcr_example.feature`
    Then it should fail with "5 scenarios (2 failed, 3 passed)"
    And the file "features/cassettes/cucumber_tags/localhost_request.yml" should contain "Hello localhost_request_1"
    And the file "features/cassettes/cucumber_tags/localhost_request.yml" should contain "Hello localhost_request_2"
    And the file "features/cassettes/nested_cassette.yml" should contain "Hello nested_cassette"
    And the file "features/cassettes/allowed.yml" should contain "Hello allowed"
    And the file "features/cassettes/VCR_example/tagged_scenario.yml" should contain "Hello localhost_request_1"
    And the file "features/cassettes/VCR_example/tagged_scenario_outline/_foo_bar_.yml" should contain "Hello localhost_request_1"

    # Run again without the server; we'll get the same responses because VCR
    # will replay the recorded responses.
    When I run `cucumber features/vcr_example.feature`
    Then it should fail with "5 scenarios (2 failed, 3 passed)"
    And the output should contain each of the following:
      | An HTTP request has been made that VCR does not know how to handle:               |
      |   GET http://localhost:7777/disallowed_1                                          |
      | An HTTP request has been made that VCR does not know how to handle:               |
      |   GET http://localhost:7777/disallowed_2                                          |
    And the file "features/cassettes/cucumber_tags/localhost_request.yml" should contain "Hello localhost_request_1"
    And the file "features/cassettes/cucumber_tags/localhost_request.yml" should contain "Hello localhost_request_2"
    And the file "features/cassettes/nested_cassette.yml" should contain "Hello nested_cassette"
    And the file "features/cassettes/allowed.yml" should contain "Hello allowed"
    And the file "features/cassettes/VCR_example/tagged_scenario.yml" should contain "Hello localhost_request_1"
    And the file "features/cassettes/VCR_example/tagged_scenario_outline/_foo_bar_.yml" should contain "Hello localhost_request_1"

  Scenario: `:allow_unused_http_interactions => false` does not raise if the scenario already failed
    Given a previously recorded cassette file "features/cassettes/cucumber_tags/example.yml" with:
      """
      --- 
      http_interactions: 
      - request: 
          method: get
          uri: http://example.com/foo
          body: 
            encoding: UTF-8
            string: ""
          headers: {}
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Length: 
            - "5"
          body: 
            encoding: UTF-8
            string: Hello
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """
    And a file named "features/support/vcr.rb" with:
      """ruby
      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'features/cassettes'
      end

      VCR.cucumber_tags do |t|
        t.tag '@example', :allow_unused_http_interactions => false
      end
      """
    And a file named "features/step_definitions/steps.rb" with:
      """ruby
      When /^the scenario fails$/ do
        raise "boom"
      end
      """
    And a file named "features/vcr_example.feature" with:
      """
      Feature:

        @example
        Scenario: tagged scenario
          When the scenario fails
      """
    When I run `cucumber features/vcr_example.feature`
    Then it should fail with "1 scenario (1 failed)"
     And the output should contain "boom"
     And the output should not contain "There are unused HTTP interactions"

