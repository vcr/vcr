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
        VCR.use_cassette('synopsis', :record => :new_episodes) do
          response = Net::HTTP.get_response(URI.parse('http://example.com/'))
          assert_match /You have reached this web page by typing.*example\.com/, response.body
        end
      end
    end

Run this test once, and VCR will record the http request to `fixtures/vcr_cassettes/synopsis.yml`.  Run it again, and VCR
will replay the response from example.com when the http request is made.  This test is now fast (no real HTTP requests are
made anymore), deterministic (the test will continue to pass, even if you are offline, or example.com goes down for
maintenance) and accurate (the response from example.com will contain the same headers and body you get from a real request).

## Features

* Automatically records and replays your HTTP interactions with minimal setup/configuration code.
* Supports multiple HTTP stubbing libraries.  Currently FakeWeb and WebMock are supported, and the adapter interface
  is easy to implement for any future libraries.
* Supports multiple HTTP libraries: [Net::HTTP](http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html)
  (all HTTP stubbing libraries), [Patron](http://github.com/toland/patron) (WebMock only),
  [HTTPClient](http://github.com/nahi/httpclient) (WebMock only) and
  [em-http-request](http://github.com/igrigorik/em-http-request) (WebMock only).
* Request matching is configurable based on HTTP method, URI, host, body and headers.
* The same request can receive different responses in different tests--just use different cassettes.
* The recorded requests and responses are stored on disk as YAML and can easily be inspected and edited.
* Dynamic responses are supported using ERB.
* Disables all HTTP requests that you don't explicitly allow.
* Simple cucumber integration is provided using tags.

## Development

* Source hosted on [GitHub](http://github.com/myronmarston/vcr).
* Direct questions and discussions to the [mailing list](http://groups.google.com/group/vcr-ruby).
* Report issues on [GitHub Issues](http://github.com/myronmarston/vcr/issues).
* Pull requests are very welcome! Please include spec and/or feature coverage for every patch,
  and create a topic branch for every separate change you make.

## Cassettes

Cassettes are the medium to which VCR records HTTP interactions, and the medium from which it replays them.
While a cassette is in use, new HTTP requests (or "new episodes", as VCR calls them) either get
recorded, or an error will be raised, depending on the cassette's `:record` mode (see below).  When you use
a cassette that contains previously recorded HTTP interactions, it registers them with the http stubbing
library of your choice (fakeweb or webmock) so that HTTP requests get the recorded response.  Between test
runs, cassettes are stored on disk as YAML files in your configured cassette library directory.

Each cassette can be configured with a couple options:

* `:record`: Specifies a record mode for this cassette.
* `:erb`: Used for dynamic cassettes (see below for more details).
* `:match_requests_on`: An array of request attributes to match on (see below for more details).

## Record modes

VCR supports 3 record modes.  You can set a default record mode in your configuration (see below) 
and a per-cassette record mode when inserting a cassette.  The record modes are:

* `:new_episodes`: Previously recorded HTTP interactions will be replayed.  New HTTP interactions will be recorded.
* `:all`: Previously recorded HTTP interactions will be ignored.  All HTTP interactions will be recorded.
* `:none`: Previously recorded HTTP interactions will be replayed.  New HTTP interactions will result in an error.

## Request Matching

In order to properly replay previously recorded requests, VCR must match new HTTP requests to a previously
recorded one.  By default, it matches on HTTP method and URI, since that is usually deterministic and
fully identifies the resource and action for typical RESTful APIs.  In some cases (such as SOAP webservices)
this may not work so well, and VCR allows you to customize how requests are matched.

Cassettes take a `:match_requests_on` option that expects an array of request attributes to match on.
Supported attributes are:

* `:method`: The HTTP method (i.e. GET, POST, PUT or DELETE) of the request.
* `:uri`: The full URI of the request.
* `:host`: The host of the URI.  You can use this as an alternative to `:uri` to cause VCR to match using
  a regex such as `/https?:\/\/example\.com/i`.
* `:body`: The body of the request.
* `:headers`: The request headers.

By default, VCR uses a `:match_requests_on` option like:

    :match_requests_on => [:uri, :method]

If you want to match on body, just add it to the array:

    :match_requests_on => [:uri, :method, :body]

Note that FakeWeb cannot match on `:body` or `:headers`.

## Configuration

    require 'vcr'

    VCR.config do |c|
      c.cassette_library_dir     = 'fixtures/cassette_library'
      c.http_stubbing_library    = :fakeweb
      c.ignore_localhost         = true
      c.default_cassette_options = { :record => :none }
    end

This can go pretty much wherever, as long as this code is run before your tests, specs or scenarios.  I tend
to put it in `spec/support/vcr.rb`, `test/support/vcr.rb` or `features/support/vcr.rb`.  You can set the following
configuration options:

* `cassette_library_dir`: VCR will save the cassette YAML files to this directory.  If you are using Rails 3 and
  ActiveRecord YAML fixtures, you will probably want to avoid putting VCR cassettes in a sub-directory of
  `RAILS_ROOT/test/fixtures`.  Rails will assume your cassette YAML files are ActiveRecord fixtures and raise an
  error when the content doesn't conform to its expectations.
* `http_stubbing_library`: Which http stubbing library to use.  Currently `:fakeweb` and `:webmock` are supported.
  This is currently optional--VCR will try to guess based on the presence or absence of the `FakeWeb` or `WebMock`
  constants, but this is mostly done to assist users upgrading from VCR 0.3.1, which only worked with fakeweb and
  didn't have this option.  I recommend you explicitly configure this.
* `ignore_localhost`: Defaults to false.  Setting it true does the following:
    * Localhost requests will proceed as normal.  The "Real HTTP connections are disabled" error will not occur.
    * Localhost requests will not be recorded.
    * Previously recorded localhost requests will not be replayed.
* `default_cassette_options`: The default options for your cassettes.  These will be overridden by any options you
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

      it "does something else that makes an HTTP request"

      after(:each) do
        VCR.eject_cassette
      end
    end

If you're using RSpec 2, you can use the new `around` hook:

    describe "Some object that makes an HTTP request" do
      around(:each) do |example|
        VCR.use_cassette('geocoding/Seattle, WA', :record => :new_episodes, &example)
      end

      it "does something that makes an HTTP request"

      it "does something else that makes an HTTP request"
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

For each of the tags you specify in your `cucumber_tags` block, VCR will set up an appropriate
[After hook](http://wiki.github.com/aslakhellesoy/cucumber/hooks) to use a cassette
for the entire scenario.  The tag (minus the '@') will be used as the cassette name, and it'll
go in the `cucumber_tags` subdirectory of the configured cassette library directory.

If the last argument to `#tags` is a hash, VCR will use it as the options for the named cassettes.

## Usage with Capybara

When you use any of the javascript-enabled drivers (selenium, celerity, culerity) with
[capybara](http://github.com/jnicklas/capybara), it'll need to ping the app running on localhost.
Set the `ignore_localhost` option to true to allow this.

## Cassette Customization

Cassettes are stored as simple plain text YAML files and can easily be edited to suit your needs.  One common need
is for a particular request to be stubbed using a regex rather than the raw URL.  This is handy for URLs that contain
non-deterministic portions (such as timestamps)--since the URL will be a bit different each time, the URL from the
recorded request will not match the URL for future requests.  You can simply change the URL to the YAML of the
appropriate regex.

Figure out the yaml in irb:

    >> require 'yaml'
    => true
    >> puts /example\.com\/\d+/.to_yaml
    --- !ruby/regexp /example\.com\/\d+/

Edit your cassette file:

    request: !ruby/struct:VCR::Request 
      method: :get
      uri: !ruby/regexp /example\.com\/\d+/
      body: 
      headers: 

## Dynamic Cassettes

VCR's default recording and replaying is static.  The exact response that is initially recorded will
be replayed for all future requests.  Usually this is fine, but in some cases you need something more
dynamic.  You can use [ERB](http://www.ruby-doc.org/stdlib/libdoc/erb/rdoc/) for this.

Enable ERB evaluation of a cassette using the `:erb` option:

    VCR.use_cassette('user-subscription', :erb => true) do
      # do something that makes an HTTP request
    end

You can use variables in your cassette's ERB by passing a hash:

    VCR.use_cassette('user-subscription', :erb => { :user => User.last }) do
      # do something that makes an HTTP request
    end

In your cassette:

    request: !ruby/struct:VCR::Request 
      method: :get
      uri: http://some-domain.com:80/users/<%= user.id %>
      body: 
      headers: 
      ...
    response: !ruby/struct:VCR::Response 
      ...
      body: Hello, <%= user.name %>!

## FakeWeb or WebMock?

VCR works fine with either FakeWeb or WebMock.  Overall, WebMock has more features, and you'll need to use
WebMock if you want to use VCR with an HTTP library besides Net::HTTP.  However, FakeWeb is currently
about three times faster than WebMock, so you may want to stick with FakeWeb if you don't need WebMock's
additional features.  You can see the
[benchmarks](http://github.com/myronmarston/vcr/blob/master/benchmarks/http_stubbing_libraries.rb) for
more details.

Note that FakeWeb also currently has a bug that prevents it from properly dealing with multiple values
for the same response header.  See [this FakeWeb issue](http://github.com/chrisk/fakeweb/issues/17) for
more info.

You should not need to directly interact with either FakeWeb or WebMock.  VCR will take care of disallowing
http connections when no cassette is inserted, and it will clean up all stubs/registrations when a cassette
is ejected.  If you ever decide to switch HTTP stubbing libraries, you'll just have to update the VCR config
setting.

## Suggested Workflow

First, configure VCR as I have above.  I like setting the default record mode to `:none` 
so that no new HTTP requests are made without me explicitly allowing it, but if you may prefer to
set it to `:new_episodes`.

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

VCR is designed to be used very granularly.  Rather than inserting a global cassette, I recommend you wrap individual
blocks of code in `VCR.use_cassette` and record logically grouped sets of requests.

## Ruby Interpreter Compatibility

VCR has been tested on the following ruby interpreters:

* MRI 1.8.6
* MRI 1.8.7
* MRI 1.9.1
* MRI 1.9.2 preview 3
* JRuby 1.5.1

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
* If you find VCR useful, please recommend me on [working with rails](http://workingwithrails.com/person/16590-myron-marston).

## Thanks

* [Aslak Hellesøy](http://github.com/aslakhellesoy) for [Cucumber](http://github.com/aslakhellesoy/cucumber).
* [Bartosz Blimke](http://github.com/bblimke) for [WebMock](http://github.com/bblimke/webmock).
* [Chris Kampmeier](http://github.com/chrisk) for [FakeWeb](http://github.com/chrisk/fakeweb).
* [Chris Young](http://github.com/chrisyoung) for [NetRecorder](http://github.com/chrisyoung/netrecorder),
  the inspiration for VCR.

Thanks also to the following people who have contributed patches or helpful suggestions:

* [Aaron Brethorst](http://github.com/aaronbrethorst)
* [Bartosz Blimke](http://github.com/bblimke)
* [Ben Hutton](http://github.com/benhutton)
* [Eric Allam](http://github.com/rubymaverick)

## Similar Libraries

If VCR doesn't meet your needs, please [open an issue](http://github.com/myronmarston/vcr/issues) and let me know
how VCR could be improved.  You may also want to try one of these similar libraries:

* [Stale Fish](http://github.com/jsmestad/stale_fish)
* [NetRecorder](http://github.com/chrisyoung/netrecorder)
* [Ephemeral Response](http://github.com/sandro/ephemeral_response)

## Copyright

Copyright (c) 2010 Myron Marston. See LICENSE for details.
