# uri_parser

By default, VCR will parse URIs using `URI` from the Ruby standard
  library. There are some URIs seen out in the wild that `URI` cannot
  parse properly. You can set the `uri_parser` configuration option
  to use a different parser (such as `Addressable::URI`) to work with
  these URIs.

  The configured URI parser needs to expose a `.parse` class method
  that returns an instance of the uri. This uri instance needs to
  implement the following API:

  * `#scheme` => a string
  * `#host`   => a string
  * `#port`   => a fixnum
  * `#path`   => a string
  * `#query`  => a string
  * `#to_s`   => a string
  * `#port=`
  * `#query=`
  * `#==`     => boolean

## Background

_Given_ a file named "cassettes/example.yml" with:

```
---
http_interactions:
- request:
    method: get
    uri: http://example.com/hello
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
  recorded_at: Tue, 25 Sep 2012 04:58:44 GMT
recorded_with: VCR 2.2.5
```

## the VCR uri parser gets its value from `uri_parser`

_Given_ a file named "uri_parser.rb" with:

```ruby
require 'vcr'
require 'uri'

module MyURI
  def self.parse(url)
    uri = URI.parse(url)
    uri.host = 'example.com'
    uri.path = '/hello'
    uri
  end
end

VCR.configure do |c|
  c.uri_parser = MyURI
  c.hook_into :webmock
  c.cassette_library_dir = 'cassettes'
end

VCR.use_cassette('example') do
  puts Net::HTTP.get_response('evil.org', '/projects').body
end
```

_When_ I run `ruby uri_parser.rb`

_Then_ it should pass with "Hello".

## the `uri_parser` defaults to the standard library's `URI`

_Given_ a file named "uri_parser_default.rb" with:

```ruby
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'cassettes'
end

VCR.use_cassette('example') do
  puts Net::HTTP.get_response('example.com', '/hello').body
end
```

_When_ I run `ruby uri_parser_default.rb`

_Then_ it should pass with "Hello".
