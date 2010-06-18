@httpclient
Feature: HTTPClient
  In order to have deterministic, fast tests that do not depend on an internet connection
  As a TDD/BDD developer
  I want VCR to work with asynchronous HTTPClient requests

  Scenario: Record an asynchronous request
    Given we do not have a "temp/asynchronous" cassette
     When I make an asynchronous HTTPClient get request to "http://example.com" within the "temp/asynchronous" cassette
     Then the "temp/asynchronous" library file should have a response for "http://example.com" that matches /You have reached this web page by typing.*example\.com/

  @copy_not_the_real_response_to_temp
  Scenario: Replay a response for an asynchronous request
    Given the "temp/not_the_real_response" library file has a response for "http://example.com" that matches /This is not the real response from example\.com/
     When I make an asynchronous HTTPClient get request to "http://example.com" within the "temp/not_the_real_response" cassette
     Then the response for "http://example.com" should match /This is not the real response from example\.com/
