# Error for HTTP request made when no cassette is in use

VCR is designed to help you remove all HTTP dependencies from your
  test suite.  To assist with this, VCR will cause an exception to be
  raised when an HTTP request is made while there is no cassette in
  use.  The error is helpful to pinpoint where HTTP requests are
  made so you can use a VCR cassette at that point in your code.

  If you want insight about how VCR attempted to handle the request,
  you can use the [debug\_logger](../configuration/debug-logging)
  configuration option to log more details.

  If you want to allow an HTTP request to proceed as normal, you can
  set the [allow\_http\_connections\_when\_no\_cassette](../configuration/allow-http-connections-when-no-cassette)
  configuration option or you can temporarily turn VCR off:

    - `VCR.turn_off!` => turn VCR off so HTTP requests are allowed.
      Cassette insertions will trigger an error.
    - `VCR.turn_off!(:ignore_cassettes => true)` => turn
      VCR off and ignore cassette insertions (so that no error is raised).
    - `VCR.turn_on!` => turn VCR back on
    - `VCR.turned_off { ... }` => turn VCR off for the duration of the
      provided block.

## Error for request when no cassette is in use

_Given_ a file named "no_cassette_error.rb" with:

```ruby
include_http_adapter_for("<http_lib>")

require 'vcr'

VCR.configure do |c|
  <configuration>
  c.cassette_library_dir = 'cassettes'
end

response_body_for(:get, 'http://example.com/')
```

_When_ I run `ruby no_cassette_error.rb`

_Then_ it should fail with "An HTTP request has been made that VCR does not know how to handle".

### Examples

| configuration         | http_lib              |
|-----------------------|-----------------------|
| c.hook_into :webmock  | net/http              |
| c.hook_into :webmock  | httpclient            |
| c.hook_into :webmock  | curb                  |
| c.hook_into :webmock  | patron                |
| c.hook_into :webmock  | em-http-request       |
| c.hook_into :webmock  | typhoeus              |
| c.hook_into :typhoeus | typhoeus              |
| c.hook_into :excon    | excon                 |
| c.hook_into :faraday  | faraday (w/ net_http) |

## Temporarily turn VCR off to allow HTTP requests to proceed as normal

_Given_ a file named "turn_off_vcr.rb" with:

```ruby
$server = start_sinatra_app do
  get('/') { 'Hello' }
end

require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
end
WebMock.allow_net_connect!

def make_request(context)
  puts context
  puts Net::HTTP.get_response('localhost', '/', $server.port).body
rescue => e
  puts "Error: #{e.class}"
end

VCR.turned_off do
  make_request "In VCR.turned_off block"
end

make_request "Outside of VCR.turned_off block"

VCR.turn_off!
make_request "After calling VCR.turn_off!"

VCR.turned_on do
  make_request "In VCR.turned_on block"
end

VCR.turn_on!
make_request "After calling VCR.turn_on!"
```

_When_ I run `ruby turn_off_vcr.rb`

_Then_ the output should contain:

```
In VCR.turned_off block
Hello
```

_And_ the output should contain:

```
Outside of VCR.turned_off block
Error: VCR::Errors::UnhandledHTTPRequestError
```

_And_ the output should contain:

```
After calling VCR.turn_off!
Hello
```

_And_ the output should contain:

```
In VCR.turned_on block
Error: VCR::Errors::UnhandledHTTPRequestError
```

_And_ the output should contain:

```
After calling VCR.turn_on!
Error: VCR::Errors::UnhandledHTTPRequestError
```

## Turning VCR off prevents cassettes from being inserted

_Given_ a file named "turn_off_vcr_and_insert_cassette.rb" with:

```ruby
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
end
WebMock.allow_net_connect!

VCR.turn_off!
VCR.insert_cassette('example')
```

_When_ I run `ruby turn_off_vcr_and_insert_cassette.rb`

_Then_ it should fail with "VCR is turned off.  You must turn it on before you can insert a cassette.".

## Turning VCR off with `:ignore_cassettes => true` ignores cassettes

_Given_ a file named "turn_off_vcr_and_insert_cassette.rb" with:

```ruby
$server = start_sinatra_app do
  get('/') { 'Hello' }
end

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
end
WebMock.allow_net_connect!

VCR.turn_off!(:ignore_cassettes => true)

VCR.use_cassette('example') do
  response = Net::HTTP.get_response('localhost', '/', $server.port).body
  puts "Response: #{response}"
end
```

_When_ I run `ruby turn_off_vcr_and_insert_cassette.rb`

_Then_ it should pass with "Response: Hello"

_And_ the file "cassettes/example.yml" should not exist.
