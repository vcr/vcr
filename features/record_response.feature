@all_http_libs
Feature: Record response
  In order to have deterministic, fast tests that do not depend on an internet connection
  As a TDD/BDD developer
  I want to record responses for new requests so I can replay them in future test runs

  Scenario: Record a response using VCR.use_cassette
    Given we do not have a "temp/cassette" cassette
     When I make an HTTP get request to "http://example.com" within the "temp/cassette" cassette
     Then the "temp/cassette" library file should have a response for "http://example.com" that matches /You have reached this web page by typing.*example\.com/

  @record_cassette1
  Scenario: Record a response using a tagged scenario
    Given we do not have a "cucumber_tags/record_cassette1" cassette
      And this scenario is tagged with the vcr cassette tag: "@record_cassette1"
     When I make an HTTP get request to "http://example.com"
     Then I can test the scenario cassette's recorded responses in the next scenario, after the cassette has been ejected

  Scenario: Check the recorded response for the previous scenario
    Given the previous scenario was tagged with the vcr cassette tag: "@record_cassette1"
     Then the "cucumber_tags/record_cassette1" library file should have a response for "http://example.com" that matches /You have reached this web page by typing.*example\.com/

  @record_cassette2
  Scenario: Use both a tagged scenario cassette and a nested cassette within a single step definition
    Given we do not have a "cucumber_tags/record_cassette2" cassette
      And we do not have a "temp/nested" cassette
      And this scenario is tagged with the vcr cassette tag: "@record_cassette2"
     When I make an HTTP get request to "http://example.com/before_nested"
      And I make an HTTP get request to "http://example.com/nested" within the "temp/nested" cassette
      And I make an HTTP get request to "http://example.com/after_nested"
     Then I can test the scenario cassette's recorded responses in the next scenario, after the cassette has been ejected
      And the "temp/nested" library file should have a response for "http://example.com/nested" that matches /The requested URL \/nested was not found/

  Scenario: Check the recorded response for the previous scenario
    Given the previous scenario was tagged with the vcr cassette tag: "@record_cassette2"
     Then the "cucumber_tags/record_cassette2" library file should have a response for "http://example.com/before_nested" that matches /The requested URL \/before_nested was not found/
      And the "cucumber_tags/record_cassette2" library file should have a response for "http://example.com/after_nested" that matches /The requested URL \/after_nested was not found/

  Scenario: Make an HTTP request in a cassette with record mode set to :all
    Given we do not have a "temp/record_all_cassette" cassette
     When I make an HTTP get request to "http://example.com" within the "temp/record_all_cassette" cassette using cassette options: { :record => :all }
     Then the "temp/record_all_cassette" library file should have a response for "http://example.com" that matches /You have reached this web page by typing.*example\.com/

  Scenario: Make an HTTP request in a cassette with record mode set to :none
    Given we do not have a "temp/record_none_cassette" cassette
     When I make an HTTP get request to "http://example.com" within the "temp/record_none_cassette" cassette using cassette options: { :record => :none }
     Then the HTTP get request to "http://example.com" should result in an error that mentions VCR
      And there should not be a "temp/record_none_cassette" library file

  @copy_not_the_real_response_to_temp
  Scenario: Make an HTTP request in a cassette with record mode set to :new_episodes
    Given we have a "temp/not_the_real_response" library file with a previously recorded response for "http://example.com"
      And we have a "temp/not_the_real_response" library file with no previously recorded response for "http://example.com/foo"
     When I make HTTP get requests to "http://example.com" and "http://example.com/foo" within the "temp/not_the_real_response" cassette
     Then the "temp/not_the_real_response" library file should have a response for "http://example.com" that matches /This is not the real response from example\.com/
      And the "temp/not_the_real_response" library file should have a response for "http://example.com/foo" that matches /The requested URL \/foo was not found/
