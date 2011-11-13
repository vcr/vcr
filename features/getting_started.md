### Install it

    [sudo] gem install vcr
    [sudo] gem install fakeweb

### Configure it

Create a file named `vcr_setup.rb` with content like:

    require 'vcr'

    VCR.configure do |c|
      c.cassette_library_dir = 'vcr_cassettes'
      c.hook_into :fakeweb
    end

Ensure this file is required by your test suite before any
of the tests are run.

### Use it

Run your tests.  Any tests that make HTTP requests using Net::HTTP will
raise errors like:

    FakeWeb::NetConnectNotAllowedError: Real HTTP connections are disabled.
    Unregistered request: GET http://example.com/.
    You can use VCR to automatically record this request and replay it later.
    For more details, visit the VCR documentation at: http://relishapp.com/myronmarston/vcr

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

