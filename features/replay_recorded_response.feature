Feature: Replay recorded response
  In order to have deterministic, fast tests that do not depend on an internet connection
  As a TDD/BDD developer
  I want to replay responses for requests I have previously recorded

  Scenario: Replay recorded response for a request in a VCR.with_cassette block
    Given the "not_the_real_response" cache file has a response for "http://example.com" that matches /This is not the real response from example\.com/
     When I make an HTTP get request to "http://example.com" within the "not_the_real_response" cassette
     Then the response for "http://example.com" should match /This is not the real response from example\.com/

  @replay_cassette1
  Scenario: Replay recorded response for a request within a tagged scenario
    Given this scenario is tagged with the vcr cassette tag: "@replay_cassette1"
      And the "cucumber_tags/replay_cassette1" cache file has a response for "http://example.com" that matches /This is not the real response from example\.com/
     When I make an HTTP get request to "http://example.com"
     Then the response for "http://example.com" should match /This is not the real response from example\.com/

  @replay_cassette2
  Scenario: Use both a tagged scenario cassette and a nested cassette within a single step definition
    Given this scenario is tagged with the vcr cassette tag: "@replay_cassette2"
      And the "cucumber_tags/replay_cassette2" cache file has a response for "http://example.com/before_nested" that matches /The before_nested response/
      And the "nested_replay_cassette" cache file has a response for "http://example.com/nested" that matches /The nested response/
      And the "cucumber_tags/replay_cassette2" cache file has a response for "http://example.com/after_nested" that matches /The after_nested response/
     When I make an HTTP get request to "http://example.com/before_nested"
      And I make an HTTP get request to "http://example.com/nested" within the "nested_replay_cassette" cassette
      And I make an HTTP get request to "http://example.com/after_nested"
     Then the response for "http://example.com/before_nested" should match /The before_nested response/
      And the response for "http://example.com/nested" should match /The nested response/
      And the response for "http://example.com/after_nested" should match /The after_nested response/

  @copy_not_the_real_response_to_temp
  Scenario: Make an HTTP request in a cassette with record mode set to :all
    Given we have a "temp/not_the_real_response" file with a previously recorded response for "http://example.com"
      And we have a "temp/not_the_real_response" file with no previously recorded response for "http://example.com/foo"
     When I make HTTP get requests to "http://example.com" and "http://example.com/foo" within the "temp/not_the_real_response" all cassette
     Then the response for "http://example.com" should match /You have reached this web page by typing.*example\.com/
      And the response for "http://example.com/foo" should match /The requested URL \/foo was not found/

  @copy_not_the_real_response_to_temp
  Scenario: Make an HTTP request in a cassette with record mode set to :none
    Given we have a "temp/not_the_real_response" file with a previously recorded response for "http://example.com"
      And we have a "temp/not_the_real_response" file with no previously recorded response for "http://example.com/foo"
     When I make HTTP get requests to "http://example.com" and "http://example.com/foo" within the "temp/not_the_real_response" none cassette
     Then the response for "http://example.com" should match /This is not the real response from example\.com/
      And the HTTP get request to "http://example.com/foo" should result in a fakeweb error that mentions VCR

  @copy_not_the_real_response_to_temp
  Scenario: Make an HTTP request in a cassette with record mode set to :unregistered
  Given we have a "temp/not_the_real_response" file with a previously recorded response for "http://example.com"
    And we have a "temp/not_the_real_response" file with no previously recorded response for "http://example.com/foo"
   When I make HTTP get requests to "http://example.com" and "http://example.com/foo" within the "temp/not_the_real_response" unregistered cassette
   Then the response for "http://example.com" should match /This is not the real response from example\.com/
    And the response for "http://example.com/foo" should match /The requested URL \/foo was not found/

  @replay_cassette3
  Scenario: Replay multiple different recorded responses for requests to the same URL
    Given this scenario is tagged with the vcr cassette tag: "@replay_cassette3"
      And the "cucumber_tags/replay_cassette3" cache file has a response for "http://example.com" that matches /This is not the real response from example\.com/
      And the "cucumber_tags/replay_cassette3" cache file has a response for "http://example.com" that matches /This is another fake response from example\.com/
     When I make an HTTP get request to "http://example.com"
      And I make an HTTP get request to "http://example.com"
     Then response 1 for "http://example.com" should match /This is not the real response from example\.com/
      And response 2 for "http://example.com" should match /This is another fake response from example\.com/

  @copy_not_the_real_response_to_temp
  Scenario: Replay a response for an asynchronous request (such as for mechanize)
    Given the "temp/not_the_real_response" cache file has a response for "http://example.com" that matches /This is not the real response from example\.com/
     When I make a replayed asynchronous HTTP get request to "http://example.com" within the "temp/not_the_real_response" unregistered cassette
     Then the response for "http://example.com" should match /This is not the real response from example\.com/
