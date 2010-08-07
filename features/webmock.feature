@webmock
Feature: Replay recorded response
  In order to have deterministic, fast tests that do not depend on an internet connection
  As a TDD/BDD developer who uses WebMock
  I want to replay responses for requests I have previously recorded

  Scenario: Use the :match_requests_on option to differentiate requests by request body (for "foo=bar")
    Given the "match_requests_on" library file has a response for "http://example.com/" with the request body "foo=bar" that matches /foo=bar response/
     When I make an HTTP post request to "http://example.com/" with request body "foo=bar" within the "match_requests_on" cassette using cassette options: { :match_requests_on => [:uri, :body], :record => :none }
     Then the response for "http://example.com/" should match /foo=bar response/

  Scenario: Use the :match_requests_on option to differentiate requests by request body (for "bar=bazz")
    Given the "match_requests_on" library file has a response for "http://example.com/" with the request body "bar=bazz" that matches /bar=bazz response/
     When I make an HTTP post request to "http://example.com/" with request body "bar=bazz" within the "match_requests_on" cassette using cassette options: { :match_requests_on => [:uri, :body], :record => :none }
     Then the response for "http://example.com/" should match /bar=bazz response/

  Scenario: Use the :match_requests_on option to differentiate requests by request header (for "X-HTTP-USER=joe")
    Given the "match_requests_on" library file has a response for "http://example.com/" with the request header "X-HTTP-USER=joe" that matches /joe response/
     When I make an HTTP post request to "http://example.com/" with request header "X-HTTP-USER=joe" within the "match_requests_on" cassette using cassette options: { :match_requests_on => [:uri, :headers], :record => :none }
     Then the response for "http://example.com/" should match /joe response/

  Scenario: Use the :match_requests_on option to differentiate requests by request header (for "X-HTTP-USER=bob")
    Given the "match_requests_on" library file has a response for "http://example.com/" with the request header "X-HTTP-USER=bob" that matches /bob response/
     When I make an HTTP post request to "http://example.com/" with request header "X-HTTP-USER=bob" within the "match_requests_on" cassette using cassette options: { :match_requests_on => [:uri, :headers], :record => :none }
     Then the response for "http://example.com/" should match /bob response/

