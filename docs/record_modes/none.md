# :none

The `:none` record mode will:

    - Replay previously recorded interactions.
    - Cause an error to be raised for any new requests.

  This is useful when your code makes potentially dangerous
  HTTP requests.  The `:none` record mode guarantees that no
  new HTTP requests will be made.

## Background

_Given_ a file named "vcr_config.rb" with:

```ruby
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
      - "5"
    body: 
      encoding: UTF-8
      string: Hello
    http_version: "1.1"
  recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
recorded_with: VCR 2.0.0
```

## Previously recorded responses are replayed

_Given_ a file named "replay_recorded_response.rb" with:

```ruby
require 'vcr_config'

VCR.use_cassette('example', :record => :none) do
  response = Net::HTTP.get_response('example.com', '/foo')
  puts "Response: #{response.body}"
end
```

_When_ I run `ruby replay_recorded_response.rb`

_Then_ it should pass with "Response: Hello".

## New requests are prevented

_Given_ a file named "prevent_new_request.rb" with:

```ruby
require 'vcr_config'

VCR.use_cassette('example', :record => :none) do
  Net::HTTP.get_response('example.com', '/bar')
end
```

_When_ I run `ruby prevent_new_request.rb`

_Then_ it should fail with "An HTTP request has been made that VCR does not know how to handle".
