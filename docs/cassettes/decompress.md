# Decode compressed response

When the `:decode_compressed_response` option is set to a truthy value, VCR
  will decompress "gzip" and "deflate" response bodies before recording.  This
  ensures that these interactions become readable and editable after being
  serialized.

  This option should be avoided if the actual decompression of response bodies
  is part of the functionality of the library or app being tested.

## Background

_Given_ a file named "decompress.rb" with:

```ruby
require 'zlib'
require 'stringio'

$server = start_sinatra_app do
  get('/') {
    content = 'The quick brown fox jumps over the lazy dog'
    io = StringIO.new

    writer = Zlib::GzipWriter.new(io)
    writer << content
    writer.close

    headers['Content-Encoding'] = 'gzip'
    io.string
  }
end

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { :serialize_with => :syck }
end
```

## The option is not set by default

_When_ I append to file "decompress.rb":

```ruby
VCR.use_cassette(:decompress) do
  Net::HTTP.start('localhost', $server.port) do |http|
    http.get('/', 'accept-encoding' => 'identity')
  end
end
```

_And_ I run `ruby decompress.rb`

_Then_ the file "cassettes/decompress.yml" should contain a YAML fragment like:

```
Content-Encoding:
- gzip
```

## The option is enabled

_When_ I append to file "decompress.rb":

```ruby
VCR.use_cassette(:decompress, :decode_compressed_response => true) do
  Net::HTTP.start('localhost', $server.port) do |http|
    http.get('/', 'accept-encoding' => 'identity')
  end
end
```

_And_ I run `ruby decompress.rb`

_Then_ the file "cassettes/decompress.yml" should contain a YAML fragment like:

```
Content-Length:
- '43'
```

_And_ the file "cassettes/decompress.yml" should contain:

```
string: The quick brown fox jumps over the lazy dog
```
