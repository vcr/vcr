# before_playback hook

The `before_playback` hook is called before a cassette sets up its
  stubs for playback.

  Your block should accept up to 2 arguments.  The first argument will be
  the HTTP interaction that is about to be used for play back.  The second
  argument will be the current cassette.

  You can also call `#ignore!` on the HTTP interaction to prevent VCR
  from playing it back.

  You can use tags to specify a cassette, otherwise your hook will apply to all cassettes.  Consider this code:

      VCR.configure do |c|
        c.before_playback(:twitter) { ... } # modify the interactions somehow
      end

      VCR.use_cassette('cassette_1', :tag => :twitter) { ... }
      VCR.use_cassette('cassette_2') { ... }

  In this example, the hook would apply to the first cassette but not the
  second cassette.

## Background

_Given_ a previously recorded cassette file "cassettes/example.yml" with:

```
---
http_interactions:
- request:
    method: get
    uri: http://localhost:7777/
    body:
      encoding: UTF-8
      string: ""
    headers: {}
  response:
    status:
      code: 200
      message: OK
    headers:
      Content-Type:
      - text/html;charset=utf-8
      Content-Length:
      - "20"
    body:
      encoding: UTF-8
      string: previously recorded response
    http_version: "1.1"
  recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
recorded_with: VCR 2.0.0
```

## Modify played back response

_Given_ a file named "before_playback_example.rb" with:

```ruby
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'cassettes'

  c.before_playback do |interaction|
    interaction.response.body = 'response from before_playback'
  end
end

VCR.use_cassette('example') do
  response = Net::HTTP.get_response('localhost', '/', 7777)
  puts "Response: #{response.body}"
end
```

_When_ I run `ruby before_playback_example.rb`

_Then_ it should pass with "Response: response from before_playback".

## Modify played back response based on the cassette

_Given_ a file named "before_playback_example.rb" with:

```ruby
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'cassettes'

  c.before_playback do |interaction, cassette|
    interaction.response.body = "response for #{cassette.name} cassette"
  end
end

VCR.use_cassette('example') do
  response = Net::HTTP.get_response('localhost', '/', 7777)
  puts "Response: #{response.body}"
end
```

_When_ I run `ruby before_playback_example.rb`

_Then_ it should pass with "Response: response for example cassette".

## Prevent playback by ignoring interaction in before_playback hook

_Given_ a file named "before_playback_ignore.rb" with:

```ruby
$server = start_sinatra_app do
  get('/') { "sinatra response" }
end

require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'cassettes'
  c.before_playback { |i| i.ignore! }
end

VCR.use_cassette('localhost', :record => :new_episodes, :match_requests_on => [:method, :host, :path]) do
  response = Net::HTTP.get_response('localhost', '/', $server.port)
  puts "Response: #{response.body}"
end
```

_When_ I run `ruby before_playback_ignore.rb`

_Then_ it should pass with "Response: sinatra response".

## Multiple hooks are run in order

_Given_ a file named "multiple_hooks.rb" with:

```ruby
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'cassettes'

  c.before_playback { puts "In before_playback hook 1" }
  c.before_playback { puts "In before_playback hook 2" }
end

VCR.use_cassette('example', :record => :new_episodes) do
  response = Net::HTTP.get_response('localhost', '/', 7777)
  puts "Response: #{response.body}"
end
```

_When_ I run `ruby multiple_hooks.rb`

_Then_ it should pass with:

```
In before_playback hook 1
In before_playback hook 2
Response: previously recorded response
```

## Use tagging to apply hooks to only certain cassettes

_Given_ a file named "tagged_hooks.rb" with:

```ruby
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'cassettes'

  c.before_playback(:tag_2) do |i|
    puts "In before_playback hook for tag_2"
  end
end

[:tag_1, :tag_2, nil].each do |tag|
  puts
  puts "Using tag: #{tag.inspect}"

  VCR.use_cassette('example', :record => :new_episodes, :tag => tag) do
    response = Net::HTTP.get_response('localhost', '/', 7777)
    puts "Response: #{response.body}"
  end
end
```

_When_ I run `ruby tagged_hooks.rb`

_Then_ it should pass with:

```
Using tag: :tag_1
Response: previously recorded response

Using tag: :tag_2
In before_playback hook for tag_2
Response: previously recorded response

Using tag: nil
Response: previously recorded response
```
