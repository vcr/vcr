# Preserve Exact Body Bytes

Some HTTP servers are not well-behaved and respond with invalid data: the response body may
  not be encoded according to the encoding specified in the HTTP headers, or there may be bytes
  that are invalid for the given encoding. The YAML and JSON serializers are not generally
  designed to handle these cases gracefully, and you may get errors when the cassette is serialized
  or deserialized. Also, the encoding may not be preserved when round-tripped through the
  serializer.

  VCR provides a configuration option to deal with cases like these. The `preserve_exact_body_bytes`
  method accepts a block that VCR will use to determine if the body of the given request or response object
  should be base64 encoded in order to preserve the bytes exactly as-is. VCR does not do this by
  default, since base64-encoding the string removes the human readability of the cassette.

  Alternately, if you want to force an entire cassette to preserve the exact body bytes,
  you can pass the `:preserve_exact_body_bytes => true` cassette option when inserting your
  cassette.

## Preserve exact bytes for response body with invalid encoding

_Given_ a file named "preserve.rb" with:

```ruby
# encoding: utf-8
string = "abc \xFA"
puts "Valid encoding: #{string.valid_encoding?}"

$server = start_sinatra_app do
  get('/') { string }
end

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
  c.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == 'ASCII-8BIT' ||
    !http_message.body.valid_encoding?
  end
end

def make_request(label)
  puts
  puts label
  VCR.use_cassette('example', :serialize_with => :json) do
    body = Net::HTTP.get_response('localhost', '/', $server.port).body
    puts "Body: #{body.inspect}"
  end
end

make_request("Recording:")
make_request("Playback:")
```

_When_ I run `ruby preserve.rb`

_Then_ the output should contain exactly:

```
Valid encoding: false

Recording:
Body: "abc \xFA"

Playback:
Body: "abc \xFA"

```

_And_ the file "cassettes/example.json" should contain:

```
        "body": {
          "encoding": "ASCII-8BIT",
          "base64_string": "YWJjIPo=\n"
        }
```

## Preserve exact bytes for cassette with `:preserve_exact_body_bytes` option

_Given_ a file named "preserve.rb" with:

```ruby
$server = start_sinatra_app do
  get('/') { "Hello World" }
end

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { :serialize_with => :json }

  c.before_record do |i|
    # otherwise Ruby 2.0 will default to UTF-8:
    i.response.body.force_encoding('US-ASCII')
  end
end

VCR.use_cassette('preserve_bytes', :preserve_exact_body_bytes => true) do
  Net::HTTP.get_response('localhost', '/', $server.port)
end

VCR.use_cassette('dont_preserve_bytes') do
  Net::HTTP.get_response('localhost', '/', $server.port)
end
```

_When_ I run `ruby preserve.rb`

_Then_ the file "cassettes/preserve_bytes.json" should contain:

```
        "body": {
          "encoding": "US-ASCII",
          "base64_string": "SGVsbG8gV29ybGQ=\n"
        }
```

_And_ the file "cassettes/dont_preserve_bytes.json" should contain:

```
        "body": {
          "encoding": "US-ASCII",
          "string": "Hello World"
        }
```
