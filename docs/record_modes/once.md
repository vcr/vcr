# :once

The `:once` record mode will:

    - Replay previously recorded interactions.
    - Record new interactions if there is no cassette file.
    - Cause an error to be raised for new requests if there is a cassette file.

  It is similar to the `:new_episodes` record mode, but will prevent new,
  unexpected requests from being made (i.e. because the request URI changed
  or whatever).

  `:once` is the default record mode, used when you do not set one.

## Background

_Given_ a file named "setup.rb" with:

```ruby
$server = start_sinatra_app do
  get('/') { 'Hello' }
end

require 'vcr'

VCR.configure do |c|
  c.hook_into                :webmock
  c.cassette_library_dir     = 'cassettes'
end
```

_And_ a previously recorded cassette file "cassettes/example.yml" with:

```yaml
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
      - "20"
    body: 
      encoding: UTF-8
      string: example.com response
    http_version: "1.1"
  recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
recorded_with: VCR 2.0.0
```

## Previously recorded responses are replayed

_Given_ a file named "replay_recorded_response.rb" with:

```ruby
require 'setup'

VCR.use_cassette('example', :record => :once) do
  response = Net::HTTP.get_response('example.com', '/foo')
  puts "Response: #{response.body}"
end
```

_When_ I run `ruby replay_recorded_response.rb`

_Then_ it should pass with "Response: example.com response".

## New requests result in an error when the cassette file exists

_Given_ a file named "error_for_new_requests_when_cassette_exists.rb" with:

```ruby
require 'setup'

VCR.use_cassette('example', :record => :once) do
  response = Net::HTTP.get_response('localhost', '/', $server.port)
  puts "Response: #{response.body}"
end
```

_When_ I run `ruby error_for_new_requests_when_cassette_exists.rb`

_Then_ it should fail with "An HTTP request has been made that VCR does not know how to handle".

## New requests get recorded when there is no cassette file

_Given_ a file named "record_new_requests.rb" with:

```ruby
require 'setup'

VCR.use_cassette('example', :record => :once) do
  response = Net::HTTP.get_response('localhost', '/', $server.port)
  puts "Response: #{response.body}"
end
```

_When_ I remove the file "cassettes/example.yml"

_And_ I run `ruby record_new_requests.rb`

_Then_ it should pass with "Response: Hello"

_And_ the file "cassettes/example.yml" should contain "Hello".
