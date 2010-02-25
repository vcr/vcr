Feature: Record response
  In order to have deterministic, fast tests that do not depend on an internet connection
  As a TDD/BDD developer
  I want to record responses for requests to URIs that are not registered with fakeweb so I can use them with fakeweb in the future

  Scenario: Record a response using VCR.with_sandbox
    Given we do not have a "temp/sandbox" sandbox
     When I make an HTTP get request to "http://example.com" within the "temp/sandbox" sandbox
     Then the "temp/sandbox" cache file should have a response for "http://example.com" that matches /You have reached this web page by typing.*example\.com/

  @record_sandbox1
  Scenario: Record a response using a tagged scenario
    Given we do not have a "cucumber_tags/record_sandbox1" sandbox
      And this scenario is tagged with the vcr sandbox tag: "@record_sandbox1"
     When I make an HTTP get request to "http://example.com"
     Then I can test the scenario sandbox's recorded responses in the next scenario, after the sandbox has been destroyed

  Scenario: Check the recorded response for the previous scenario
    Given the previous scenario was tagged with the vcr sandbox tag: "@record_sandbox1"
     Then the "cucumber_tags/record_sandbox1" cache file should have a response for "http://example.com" that matches /You have reached this web page by typing.*example\.com/

  @record_sandbox2
  Scenario: Use both a tagged scenario sandbox and a nested sandbox within a single step definition
    Given we do not have a "cucumber_tags/record_sandbox2" sandbox
      And we do not have a "temp/nested" sandbox
      And this scenario is tagged with the vcr sandbox tag: "@record_sandbox2"
     When I make an HTTP get request to "http://example.com/before_nested"
      And I make an HTTP get request to "http://example.com/nested" within the "temp/nested" sandbox
      And I make an HTTP get request to "http://example.com/after_nested"
     Then I can test the scenario sandbox's recorded responses in the next scenario, after the sandbox has been destroyed
      And the "temp/nested" cache file should have a response for "http://example.com/nested" that matches /The requested URL \/nested was not found/

  Scenario: Check the recorded response for the previous scenario
    Given the previous scenario was tagged with the vcr sandbox tag: "@record_sandbox2"
     Then the "cucumber_tags/record_sandbox2" cache file should have a response for "http://example.com/before_nested" that matches /The requested URL \/before_nested was not found/
      And the "cucumber_tags/record_sandbox2" cache file should have a response for "http://example.com/after_nested" that matches /The requested URL \/after_nested was not found/

  Scenario: Make an HTTP request in a sandbox with record mode set to :all
    Given we do not have a "temp/record_all_sandbox" sandbox
     When I make an HTTP get request to "http://example.com" within the "temp/record_all_sandbox" all sandbox
     Then the "temp/record_all_sandbox" cache file should have a response for "http://example.com" that matches /You have reached this web page by typing.*example\.com/

  Scenario: Make an HTTP request in a sandbox with record mode set to :none
    Given we do not have a "temp/record_none_sandbox" sandbox
     When I make an HTTP get request to "http://example.com" within the "temp/record_none_sandbox" none sandbox
     Then the HTTP get request to "http://example.com" should result in a fakeweb error
      And there should not be a "temp/record_none_sandbox" cache file

  @copy_not_the_real_response_to_temp
  Scenario: Make an HTTP request in a sandbox with record mode set to :unregistered
    Given we have a "temp/not_the_real_response" file with a previously recorded response for "http://example.com"
      And we have a "temp/not_the_real_response" file with no previously recorded response for "http://example.com/foo"
     When I make HTTP get requests to "http://example.com" and "http://example.com/foo" within the "temp/not_the_real_response" unregistered sandbox
     Then the "temp/not_the_real_response" cache file should have a response for "http://example.com" that matches /This is not the real response from example\.com/
      And the "temp/not_the_real_response" cache file should have a response for "http://example.com/foo" that matches /The requested URL \/foo was not found/