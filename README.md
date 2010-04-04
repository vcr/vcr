# VCR

Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.

## Installation

    gem install vcr

You'll also need either [FakeWeb](http://github.com/chrisk/fakeweb) or [WebMock](http://github.com/bblimke/webmock):

    gem install fakeweb

or

    gem install webmock

## Synopsis

    require 'test/unit'
    require 'vcr'

    VCR.config do |c|
      c.cassette_library_dir = 'fixtures/vcr_cassettes'
      c.http_stubbing_library = :fakeweb # or :webmock
    end

    class VCRTest < Test::Unit::TestCase
      def test_example_dot_com
        response = VCR.use_cassette('synopsis', :record => :new_episodes) do
          Net::HTTP.get_response(URI.parse('http://example.com/'))
        end
        assert_match /You have reached this web page by typing.*example\.com/, response.body
      end
    end

Run this test once, and VCR will record the http request to `fixtures/vcr_cassettes/synopsis.yml`.  Run it again, and VCR
will replay the response from example.com when the http request is made.  This test is now fast (no real HTTP requests are
made anymore), deterministic (the test will continue to pass, even if you are offline, or example.com goes down for
maintenance) and accurate (the response from example.com will contain the same headers and body you get from a real request).

## Cassettes

Cassettes are the medium to which VCR records HTTP interactions, and the medium from which it replays them.  
While a cassette is in use, new HTTP requests (or "new episodes", as VCR calls them) either get 
recorded, or an error will be raised, depending on the cassette's `:record` mode (see below).  When you use
a cassette that contains previously recorded HTTP interactions, it registers them with the http stubbing
library of your choice (fakeweb or webmock) so that HTTP requests get the recorded response.  Between test
runs, cassettes are stored on disk as YAML files in your configured cassette library directory.

Each cassette can be configured with a couple options:

* `:record`: Specifies a record mode for this cassette.
* `:allow_real_http`: You can use this to force VCR to always allow a real HTTP request for particular URIs.

For example, to prevent the VCR cassette from recording and replaying requests to google.com, you could use:

    lambda { |uri| uri.host == 'google.com' }

All non-google requests would be recorded/replayed as normal.  You can also set this to `:localhost`,
which is syntactic sugar for:

    lambda { |uri| uri.host == 'localhost' }

This is particularly useful for using VCR with [capybara](http://github.com/jnicklas/capybara)
and any of its javascript drivers (see below for more info).

## Record modes

VCR supports 3 record modes.  You can set a default record mode in your configuration (see below) 
and a per-cassette record mode when inserting a cassette.  The record modes are:

* `:new_episodes`: Previously recorded HTTP interactions will be replayed.  New HTTP interactions will be recorded.
* `:all`: Previously recorded HTTP interactions will be ignored.  All HTTP interactions will be recorded.
* `:none`: Previously recorded HTTP interactions will be replayed.  New HTTP interactions will result in an error.

## Configuration

    require 'vcr'

    VCR.config do |c|
      c.cassette_library_dir     = File.join(Rails.root, 'features', 'fixtures', 'cassette_library')
      c.http_stubbing_library    = :fakeweb
      c.default_cassette_options = { :record => :none }
    end

This can go pretty much wherever, as long as this code is run before your tests, specs or scenarios.  I tend
to put it in `spec/support/vcr.rb`, `test/support/vcr.rb` or `features/support/vcr.rb`.  You can set the following
configuration options:

* `cassette_library_dir`: VCR will save the cassette YAML files to this directory.
* `http_stubbing_library`: Which http stubbing library to use.  Currently `:fakeweb` and `:webmock` are supported.
  This is currently optional--VCR will try to guess based on the presence or absence of the `FakeWeb` or `WebMock`
  constants, but this is mostly done to assist users upgrading from VCR 0.3.1, which only worked with fakeweb and
  didn't have this option.  I recommend you explicitly configure this.
* `default_cassette_options`: The default options for your cassettes.  These will be overriden by any options you
  set on each individual cassette.

## Usage with your favorite ruby test/spec framework

VCR can easily be used with any ruby test or spec framework.  Usually, you'll want to use `VCR.use_cassette`:

    VCR.use_cassette('geocoding/Seattle, WA', :record => :new_episodes) do
      # do something that makes an HTTP request
    end

Alternately, you can insert and eject a cassette with individual method calls from setup/before and teardown/after:

    describe "Some object that makes an HTTP request" do
      before(:each) do
        VCR.insert_cassette('geocoding/Seattle, WA', :record => :new_episodes)
      end

      it "does something that makes an HTTP request"

      after(:each) do
        VCR.eject_cassette
      end
    end

## Usage with Cucumber

VCR provides additional support for cucumber.  You can of course use `VCR.use_cassette` within a step definition,
and that's the recommended way for any of your custom step definitions.  But many times I find myself using generic
step definitions provided by another library (such as the webrat/capybara web steps generated by cucumber-rails),
and you don't want to modify these.  VCR provides cucumber tagging support to help in these cases.

First, tag your scenario with something descriptive:

    @facebook_http_request
    Scenario: Sign up with facebook connect

Then let VCR know about this tag, in `features/support/vcr.rb` (or some similar support file):

    VCR.cucumber_tags do |t|
      t.tags '@facebook_http_request', '@twitter_status_update', :record => :none
      t.tags '@another_scenario_tag'
    end

For each of the tags you specify in your `cucumber_tags` block, VCR will set up the appropriate
[Before and After hooks](http://wiki.github.com/aslakhellesoy/cucumber/hooks) to use a cassette
for the entire scenario.  The tag (minus the '@') will be used as the cassette name, and it'll
go in the `cucumber_tags` subdirectory of the configured cassette library directory.

If the last argument to `#tags` is a hash, VCR will use it as the options for the named cassettes.

## Usage with Capybara

When you use any of the javascript-enabled drivers (selenium, celerity, culerity) with
[capybara](http://github.com/jnicklas/capybara), it'll need to ping the app running on localhost.
Set the `:allow_real_http => :localhost` option on your cassettes to allow this (or set it as a
default cassette option in your configuration).

## Suggested Workflow

First, configure VCR as I have above.  I like setting the default record mode to `:none` 
so that no new HTTP requests are made without me explicitly allowing it.

When an HTTP request is made, you'll get an error such as:

    Real HTTP connections are disabled. Unregistered request: get http://example.com

Find the place that is making the HTTP request (the backtrace should help here).  If you've already recorded this HTTP
request to a cassette from a different test, you can simply re-use the cassette.  Use `VCR.use_cassette`, as
shown above.  You may also want to refactor this into a helper method that sets up the VCR cassette and does whatever
makes the HTTP request:

    def set_user_address(user, address, city, state)
      VCR.use_cassette("geocoding/#{address}, #{city}, #{state}", :record => :new_episodes) do
        user.address.update_attributes!(:address => address, :city => city, :state => state)
      end
    end

In this case, I've used a dynamic cassette name based on the address being geocoded.  That way, each separate address
gets a different cassette, and tests that set the same user address will reuse the same cassette.  I've also set
the record mode to `:new_episodes` so that VCR will automatically record geocoding requests for a new address
to a new cassette, without me having to change any code.

If the HTTP request that triggered the error is new, you'll have to record it for the first time.  Simply use 
`VCR.use_cassette` with the record mode set to `:new_episodes` or `:all`.  Run the test again, and VCR will 
record the HTTP interaction.  I usually remove the record mode at this point so that it uses the default
of `:none` in the future.  Future test runs will get the recorded response, and if your code changes so 
that it is making a new HTTP request, you'll be notified by an error as shown above.

## Ruby Version Compatibility

VCR works on ruby [1.8.6](http://integrity186.heroku.com/vcr), [1.8.7](http://integrity187.heroku.com/vcr) and 
[1.9.1](http://integrity191.heroku.com/vcr).

## Notes, etc.

* The objects serialized to the cassette YAML files changed with the 0.4 release.  Cassettes recorded with
  older versions of VCR will not work with VCR 0.4.0 and later.  However, VCR provides a rake task to migrate
  your old cassettes to the new format--see the [changelog](http://github.com/myronmarston/vcr/blob/master/CHANGELOG.md)
  for more info.
* The cassette name determines the name of the library file for the given cassette.  Strings or symbols are fine,
  and you can include any characters, but spaces and invalid file name characters will be removed
  before the cassette reads or writes to its library file.
* You can use a directory separator (i.e. '/') in your cassette names to cause it to use a subdirectory
  of the cassette library directory.  The cucumber tagging support uses this.
* VCR maintains a simple stack of cassettes.  This allows you to nest them as deeply as you want.
  This is particularly useful when you have a cucumber step definition that uses a cassette, and
  you also want to use a cassette for the entire scenario using the tagging support.

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Thanks

* [Aslak Hellesøy](http://github.com/aslakhellesoy) for [Cucumber](http://github.com/aslakhellesoy/cucumber).
* [Bartosz Blimke](http://github.com/bblimke) for [WebMock](http://github.com/bblimke/webmock)
* [Chris Kampmeier](http://github.com/chrisk) for [FakeWeb](http://github.com/chrisk/fakeweb).
* [Chris Young](http://github.com/chrisyoung) for [NetRecorder](http://github.com/chrisyoung/netrecorder),
  the inspiration for VCR.

## Copyright

Copyright (c) 2010 Myron Marston. See LICENSE for details.