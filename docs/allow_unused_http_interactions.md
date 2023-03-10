# Allow Unused HTTP Interactions

If set to false, this cassette option will cause VCR to raise an error
  when a cassette is ejected and there are unused HTTP interactions remaining,
  unless there is already an exception unwinding the callstack.

  It verifies that all requests included in the cassette were made, and allows
  VCR to function a bit like a mock object at the HTTP layer.

  The option defaults to true (mostly for backwards compatibility).

## Background

_Given_ a file named "vcr_config.rb" with:

```ruby
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'cassettes'
end
```

_And_ a previously recorded cassette file "cassettes/example.yml" with:

```yml
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

## Unused HTTP interactions are allowed by default

_Given_ a file named "allowed_by_default.rb" with:

```ruby
require 'vcr_config'

VCR.use_cassette("example") do
  # no requests
end
```

_When_ I run `ruby allowed_by_default.rb`

_Then_ it should pass.

## Error raised if option is false and there are unused interactions

_Given_ a file named "disallowed_with_no_requests.rb" with:

```ruby
require 'vcr_config'

VCR.use_cassette("example", :allow_unused_http_interactions => false) do
  # no requests
end
```

_When_ I run `ruby disallowed_with_no_requests.rb`

_Then_ it should fail with an error like:

```
There are unused HTTP interactions left in the cassette:
  - [get http://example.com/foo] => [200 "Hello"]
```

## No error raised if option is false and all interactions are used

_Given_ a file named "disallowed_with_all_requests.rb" with:

```ruby
require 'vcr_config'

VCR.use_cassette("example", :allow_unused_http_interactions => false) do
  Net::HTTP.get_response(URI("http://example.com/foo"))
end
```

_When_ I run `ruby disallowed_with_all_requests.rb`

_Then_ it should pass.

## Does not silence other errors raised in `use_cassette` block

_Given_ a file named "does_not_silence_other_errors.rb" with:

```ruby
require 'vcr_config'

VCR.use_cassette("example", :allow_unused_http_interactions => false) do
  raise "boom"
end
```

_When_ I run `ruby does_not_silence_other_errors.rb`

_Then_ it should fail with "boom"

_And_ the output should not contain "There are unused HTTP interactions".
