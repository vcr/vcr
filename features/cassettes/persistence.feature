Feature: Cassette Persistence

  By default, cassettes will be persisted to the file system. However, you
  can easily configure VCR to persist the cassettes to a database, a key-value
  store, or anywhere you like.

  To use something besides the file system, you must provide an object
  that provides a hash-like interface:

    * `persister[name]` should return the content previously persisted for the
      given cassette name.
    * `persister[name] = content` should persist the content for the
      given cassette name.

  Register this object with VCR, and then you can configure all cassettes
  to use it (using the `default_cassette_options`) or just some cassettes
  to use it (by passing it as an option to individual cassettes).

  Scenario: Persist cassettes in Redis
    Given the redis DB has no data
      And a file named "use_redis.rb" with:
      """ruby
      if ARGV.include?('--with-server')
        start_sinatra_app(:port => 7777) do
          get('/') { "Hello" }
        end
      end

      require 'redis'

      class RedisCassettePersister
        def initialize(redis)
          @redis = redis
        end

        def [](name)
          @redis.get(name)
        end

        def []=(name, content)
          @redis.set(name, content)
        end
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_persisters[:redis] = RedisCassettePersister.new(Redis.connect)
        c.default_cassette_options = { :persist_with => :redis }
      end

      VCR.use_cassette("redis_example") do
        response = Net::HTTP.get_response('localhost', '/', 7777)
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby use_redis.rb --with-server`
    Then it should pass with "Hello"
     And the value stored at the redis key "redis_example.yml" should include "Hello"

    When I run `ruby use_redis.rb`
    Then it should pass with "Hello"
