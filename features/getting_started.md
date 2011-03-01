## Getting Started

### Install it

    [sudo] gem install vcr
    [sudo] gem install fakeweb

### Configure it

Create a file named `vcr_setup.rb` with content like:

    require 'vcr'

    VCR.config do |c|
      c.cassette_library_dir = 'vcr_cassettes'
      c.stub_with :fakeweb
      c.default_cassette_options = { :record => :once }
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
    - !ruby/struct:VCR::HTTPInteraction 
      request: !ruby/struct:VCR::Request 
        method: :get
        uri: http://example.com:80/
        body: 
        headers: 
      response: !ruby/struct:VCR::Response 
        status: !ruby/struct:VCR::ResponseStatus 
          code: 200
          message: OK
        headers: 
          content-type: 
          - text/html;charset=utf-8
          content-length: 
          - "26"
        body: This is the response body.
        http_version: "1.1"

Disconnect your computer from the internet.  Run the test again.
It should pass since VCR is automatically replaying the recorded
response when the request is made.

