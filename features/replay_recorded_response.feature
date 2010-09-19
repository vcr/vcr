@all_http_libs
Feature: Replay recorded response
  In order to have deterministic, fast tests that do not depend on an internet connection
  As a TDD/BDD developer
  I want to replay responses for requests I have previously recorded

  Scenario: Replay recorded response for a request in a VCR.use_cassette block
    Given the "not_the_real_response" library file has a response for "http://example.com/" that matches /This is not the real response from example\.com/
     When I make an HTTP get request to "http://example.com/" while using the "not_the_real_response" cassette
     Then the response for "http://example.com/" should match /This is not the real response from example\.com/

  @replay_cassette1
  Scenario: Replay recorded response for a request within a tagged scenario
    Given this scenario is tagged with the vcr cassette tag: "@replay_cassette1"
      And the "cucumber_tags/replay_cassette1" library file has a response for "http://example.com/" that matches /This is not the real response from example\.com/
     When I make an HTTP get request to "http://example.com/"
     Then the response for "http://example.com/" should match /This is not the real response from example\.com/

  @replay_cassette2
  Scenario: Use both a tagged scenario cassette and a nested cassette within a single step definition
    Given this scenario is tagged with the vcr cassette tag: "@replay_cassette2"
      And the "cucumber_tags/replay_cassette2" library file has a response for "http://example.com/before_nested" that matches /The before_nested response/
      And the "nested_replay_cassette" library file has a response for "http://example.com/nested" that matches /The nested response/
      And the "cucumber_tags/replay_cassette2" library file has a response for "http://example.com/after_nested" that matches /The after_nested response/
     When I make an HTTP get request to "http://example.com/before_nested"
      And I make an HTTP get request to "http://example.com/nested" while using the "nested_replay_cassette" cassette
      And I make an HTTP get request to "http://example.com/after_nested"
     Then the response for "http://example.com/before_nested" should match /The before_nested response/
      And the response for "http://example.com/nested" should match /The nested response/
      And the response for "http://example.com/after_nested" should match /The after_nested response/

  @copy_not_the_real_response_to_temp
  Scenario: Make an HTTP request in a cassette with record mode set to :all
    Given we have a "temp/not_the_real_response" library file with a previously recorded response for "http://example.com/"
      And we have a "temp/not_the_real_response" library file with no previously recorded response for "http://example.com/foo"
     When I make HTTP get requests to "http://example.com/" and "http://example.com/foo" while using the "temp/not_the_real_response" cassette using cassette options: { :record => :all }
     Then the response for "http://example.com/" should match /You have reached this web page by typing.*example\.com/
      And the response for "http://example.com/foo" should match /The requested URL \/foo was not found/

  @copy_not_the_real_response_to_temp
  Scenario: Make an HTTP request in a cassette with record mode set to :none
    Given we have a "temp/not_the_real_response" library file with a previously recorded response for "http://example.com/"
      And we have a "temp/not_the_real_response" library file with no previously recorded response for "http://example.com/foo"
     When I make HTTP get requests to "http://example.com/" and "http://example.com/foo" while using the "temp/not_the_real_response" cassette using cassette options: { :record => :none }
     Then the response for "http://example.com/" should match /This is not the real response from example\.com/
      And the HTTP get request to "http://example.com/foo" should result in an error that mentions VCR

  @copy_not_the_real_response_to_temp
  Scenario: Make an HTTP request in a cassette with record mode set to :new_episodes
    Given we have a "temp/not_the_real_response" library file with a previously recorded response for "http://example.com/"
      And we have a "temp/not_the_real_response" library file with no previously recorded response for "http://example.com/foo"
     When I make HTTP get requests to "http://example.com/" and "http://example.com/foo" while using the "temp/not_the_real_response" cassette
     Then the response for "http://example.com/" should match /This is not the real response from example\.com/
      And the response for "http://example.com/foo" should match /The requested URL \/foo was not found/

  @replay_cassette3
  Scenario: Replay multiple different recorded responses for requests to the same URL
    Given this scenario is tagged with the vcr cassette tag: "@replay_cassette3"
      And the "cucumber_tags/replay_cassette3" library file has a response for "http://example.com/" that matches /This is not the real response from example\.com/
      And the "cucumber_tags/replay_cassette3" library file has a response for "http://example.com/" that matches /This is another fake response from example\.com/
     When I make an HTTP get request to "http://example.com/"
      And I make an HTTP get request to "http://example.com/"
     Then response 1 for "http://example.com/" should match /This is not the real response from example\.com/
      And response 2 for "http://example.com/" should match /This is another fake response from example\.com/

  @regex_cassette
  Scenario: Replay a cassette with a regex URI
    Given this scenario is tagged with the vcr cassette tag: "@regex_cassette"
      And the "cucumber_tags/regex_cassette" library file has a response for /example\.com\/reg/ that matches /This is the response from the regex cassette/
     When I make an HTTP get request to "http://example.com/regex1"
      And I make an HTTP get request to "http://example.com/regex2"
      And I make an HTTP get request to "http://example.com/something_else"
     Then the response for "http://example.com/regex1" should match /This is the response from the regex cassette/
      And the response for "http://example.com/regex2" should match /This is the response from the regex cassette/
      And the HTTP get request to "http://example.com/something_else" should result in an error that mentions VCR

  Scenario: Replay recorded erb response
    Given the "erb_cassette" library file has a response for "http://example.com/embedded_ruby_code" that matches /Some embedded ruby code[\S\s]*The value of some_variable is/
     When I make an HTTP get request to "http://example.com/embedded_ruby_code" while using the "erb_cassette" cassette using cassette options: { :record => :none, :erb => { :some_variable => 'foo-bar' } }
     Then the response for "http://example.com/embedded_ruby_code" should match /Some embedded ruby code: 7[\S\s]*The value of some_variable is: foo-bar/

  @create_replay_localhost_cassette @spawns_localhost_server
  Scenario: Replay recorded localhost response with ignore_localhost = false
    Given the ignore_localhost config setting is set to false
      And the "temp/replay_localhost_cassette" library file has a response for localhost that matches /This is a fake response/
      And a rack app is running on localhost that returns "localhost response" for all requests
     When I make an HTTP get request to the localhost rack app while using the "temp/replay_localhost_cassette" cassette
     Then the response for the localhost rack app should match /This is a fake response/

  @create_replay_localhost_cassette @spawns_localhost_server
  Scenario: Replay recorded localhost response with ignore_localhost = true
    Given the ignore_localhost config setting is set to true
      And the "temp/replay_localhost_cassette" library file has a response for localhost that matches /This is a fake response/
      And a rack app is running on localhost that returns "localhost response" for all requests
     When I make an HTTP get request to the localhost rack app while using the "temp/replay_localhost_cassette" cassette
     Then the response for the localhost rack app should match /localhost response/
