# Usage with Test::Unit

To use VCR with Test::Unit, wrap the body of any test method in
  `VCR.use_cassette`.

## Use `VCR.use_cassette` in a test

_Given_ a file named "test/test_server.rb" with:

```ruby
$server = start_sinatra_app do
  get('/') { "Hello" }
end
```

_Given_ a file named "test/test_helper.rb" with:

```ruby
require 'test/test_server' if ENV['SERVER'] == 'true'
require 'test/unit'
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.default_cassette_options = {
    :match_requests_on => [:method, :host, :path]
  }
end
```

_And_ a file named "test/vcr_example_test.rb" with:

```ruby
require 'test_helper'

class VCRExampleTest < Test::Unit::TestCase
  def test_use_vcr
    VCR.use_cassette('test_unit_example') do
      response = Net::HTTP.get_response('localhost', '/', $server ? $server.port : 0)
      assert_equal "Hello", response.body
    end
  end
end
```

_And_ the directory "test/fixtures/vcr_cassettes" does not exist

_When_ I set the "SERVER" environment variable to "true"

_And_ I run `ruby -Itest test/vcr_example_test.rb`

_Then_ it should pass with "1 tests, 1 assertions, 0 failures, 0 errors"

_And_ the file "test/fixtures/vcr_cassettes/test_unit_example.yml" should contain "Hello"

_When_ I set the "SERVER" environment variable to "false"

_And_ I run `ruby -Itest test/vcr_example_test.rb`

_Then_ it should pass with "1 tests, 1 assertions, 0 failures, 0 errors".
