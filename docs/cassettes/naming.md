# Naming

When inserting or using a cassette, the first argument is the cassette name.
  You can use any string for the name.  If you use the default `:file_system`
  storage backend, VCR will sanitize the string before using it as a file name,
  so that it is a file-system friendly file name.

## Name sanitizing

_Given_ a file named "name_sanitizing.rb" with:

```ruby
$server = start_sinatra_app do
  get('/') { "Hello" }
end

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
end

VCR.use_cassette('Fee, Fi Fo Fum') do
  Net::HTTP.get_response('localhost', '/', $server.port)
end
```

_And_ the directory "cassettes" does not exist

_When_ I run `ruby name_sanitizing.rb`

_Then_ the file "cassettes/Fee_Fi_Fo_Fum.yml" should contain "Hello".
