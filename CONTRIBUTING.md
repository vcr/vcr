## Contributing

Install [bundler](http://gembundler.com/) and use it to install all the development dependencies:

```console
gem install bundler
bundle install
```

You should be able to run the tests now:

```console
bundle exec rake
```

VCR uses [RSpec](http://github.com/rspec/rspec) for unit tests.  The specs are written in a very "focused" style, where each spec is concerned only with exercising the object under test, using mocks as necessary.  You can run the specs using `rake spec`.

[Cucumber](http://cukes.info/) is used for end-to-end full stack integration tests that also function as VCR's documentation.

## Problems running bundle install?

If you get an error while running `bundle install`, it may be one of the "extras" gems which are not required for development. Try installing it without these gems.

```console
bundle install --without extras
```
