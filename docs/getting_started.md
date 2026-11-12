### Install it

    [sudo] gem install vcr
    [sudo] gem install webmock

### Configure it

Create a file named `vcr_setup.rb` with content like:

    require 'vcr'

    VCR.configure do |c|
      c.cassette_library_dir = 'vcr_cassettes'
      c.hook_into :webmock
    end

Ensure this file is required by your test suite before any
of the tests are run.

### Use it

Run your tests.  Any tests that make HTTP requests using Net::HTTP will
raise errors like:

    ================================================================================
    An HTTP request has been made that VCR does not know how to handle:
      GET http://example.com/

    There is currently no cassette in use. There are a few ways
    you can configure VCR to handle this request:

      * If you want VCR to record this request and play it back during future test
        runs, you should wrap your test (or this portion of your test) in a
        `VCR.use_cassette` block [1].
      * If you only want VCR to handle requests made while a cassette is in use,
        configure `allow_http_connections_when_no_cassette = true`. VCR will
        ignore this request since it is made when there is no cassette [2].
      * If you want VCR to ignore this request (and others like it), you can
        set an `ignore_request` callback [3].

    [1] https://www.relishapp.com/myronmarston/vcr/v/2-0-0/docs/getting-started
    [2] https://www.relishapp.com/myronmarston/vcr/v/2-0-0/docs/configuration/allow-http-connections-when-no-cassette
    [3] https://www.relishapp.com/myronmarston/vcr/v/2-0-0/docs/configuration/ignore-request
    ================================================================================

Find one of these tests (preferably one that uses the same HTTP method and
request URL every time--if not, you'll have to configure the request matcher).
Wrap the body of it (or at least the code that makes the HTTP request) in a
`VCR.use_cassette` block:

    VCR.use_cassette('whatever cassette name you want') do
       # the body of the test would go here...
    end

Run this test.  It will record the HTTP request to disk as a cassette (a
test fixture), with content like:

    ---
    http_interactions:
    - request:
        method: get
        uri: http://example.com/
        body: ''
        headers: {}
      response:
        status:
          code: 200
          message: OK
        headers:
          Content-Type:
          - text/html;charset=utf-8
          Content-Length:
          - '26'
        body: This is the response body
        http_version: '1.1'
      recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
    recorded_with: VCR 2.0.0

Disconnect your computer from the internet.  Run the test again.
It should pass since VCR is automatically replaying the recorded
response when the request is made.

