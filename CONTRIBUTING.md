## Contributing

Install [bundler](http://gembundler.com/) and use it to install all the development dependencies:

```console
gem install bundler
bundle install
```

Next setup the Git submodules:

```console
git submodule init
git submodule update
```

or using the single command form

```console
git submodule update --init
```

Make sure you have redis running on your machine.

```console
redis-server /usr/local/etc/redis.conf
```

You should be able to run the tests now:

```console
bundle exec rake
```

VCR uses [RSpec 2](http://github.com/rspec/rspec) for unit tests.  The specs are written in a very "focused" style, where each spec is concerned only with exercising the object under test, using mocks as necessary.  You can run the specs using `rake spec`.

[Cucumber](http://cukes.info/) is used for end-to-end full stack integration tests that also function as VCR's documentation.

## Problems running bundle install?

If you get an error while running `bundle install`, it may be one of the "extras" gems which are not required for development. Try installing it without these gems.

```console
bundle install --without extras
```

If you are getting an error installing `rb-fsevent` gem, you may want to temporarily change the Gemfile to use the pre-release version of the gem.

```ruby
gem 'rb-fsevent', '0.9.0.pre4'
```

