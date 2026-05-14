# Custom Metadata

Custom metadata can be used to store extra data alongside
  the recordings for later retrieval using `VCR::Cassette#metadata`.

  This can be useful for example when writing tests against an API that
  does not allow the same data, such as an email, to be added twice.

    VCR.use_cassette("example").tap do |cassette|
      postfix = cassette.metadata["user_email_postfix"] ||= SecureRandom.uuid
      Net::HTTP.new('example.com', $server.port).post('/users', "email=user+#{postfix}@example.com").body 
    end

## Saving custom metadata to a cassette

_Given_ a file named "metadata.rb" with:

```ruby
$server = start_sinatra_app do
  get('/') { "Hello" }
end

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
end

VCR.use_cassette('metadata') do |cassette|
  cassette.metadata['my_metadata'] = 'My Metadata'

  Net::HTTP.get_response('localhost', '/', $server.port)
end
```

_And_ the directory "cassettes" does not exist

_When_ I run `ruby metadata.rb`

_Then_ the file "cassettes/metadata.yml" should contain "My Metadata".

## Retrieving custom metadata from a cassette

_Given_ a previously recorded cassette file "cassettes/metadata.yml" with:

```
--- 
http_interactions: 
- request: 
    method: get
    uri: http://example.com/events/since/2013-09-23T17:00:30Z
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
      string: Some Event
    http_version: "1.1"
  recorded_at: Mon, 23 Sep 2013 17:00:30 GMT
recorded_with: VCR 2.0.0
metadata:
  my_metadata: My Metadata
```

_Given_ a file named "metadata.rb" with:

```ruby
require 'vcr'

VCR.configure do |vcr|
  vcr.cassette_library_dir = 'cassettes'
  vcr.hook_into :webmock
end

VCR.use_cassette('metadata') do |cassette|
  puts "Metadata: #{cassette.metadata.fetch('my_metadata')}"
end
```

_When_ I run `ruby metadata.rb`

_Then_ it should pass with "Metadata: My Metadata".
