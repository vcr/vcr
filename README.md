# VCR

Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.

[![Build Status](https://secure.travis-ci.org/myronmarston/vcr.png?branch=master)](http://travis-ci.org/myronmarston/vcr)
[![Dependency Status](https://gemnasium.com/myronmarston/vcr.png)](https://gemnasium.com/myronmarston/vcr)

## Synopsis

``` ruby
require 'rubygems'
require 'test/unit'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock # or :fakeweb
end

class VCRTest < Test::Unit::TestCase
  def test_example_dot_com
    VCR.use_cassette('synopsis') do
      response = Net::HTTP.get_response(URI('http://www.iana.org/domains/example/'))
      assert_match /Example Domains/, response.body
    end
  end
end
```

Run this test once, and VCR will record the http request to `fixtures/vcr_cassettes/synopsis.yml`.  Run it again, and VCR
will replay the response from iana.org when the http request is made.  This test is now fast (no real HTTP requests are
made anymore), deterministic (the test will continue to pass, even if you are offline, or iana.org goes down for
maintenance) and accurate (the response will contain the same headers and body you get from a real request).

## Features

* Automatically records and replays your HTTP interactions with minimal setup/configuration code.
* Supports and works with the HTTP stubbing facilities of multiple libraries.  Currently, the
  following are supported:
  * [FakeWeb](https://github.com/chrisk/fakeweb)
  * [WebMock](https://github.com/bblimke/webmock)
  * [Typhoeus](https://github.com/dbalatero/typhoeus)
  * [Faraday](https://github.com/technoweenie/faraday)
  * [Excon](https://github.com/geemus/excon)
* Supports multiple HTTP libraries:
  * [Patron](http://github.com/toland/patron) (when using WebMock)
  * [Curb](http://github.com/taf2/curb) (when using WebMock -- only supports Curl::Easy at the moment)
  * [HTTPClient](http://github.com/nahi/httpclient) (when using WebMock)
  * [em-http-request](http://github.com/igrigorik/em-http-request) (when using WebMock)
  * [Net::HTTP](http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html) (when using FakeWeb and WebMock)
  * [Typhoeus](https://github.com/dbalatero/typhoeus) (Typhoeus::Hydra, but not Typhoeus::Easy or Typhoeus::Multi)
  * [Excon](https://github.com/geemus/excon)
  * [Faraday](https://github.com/technoweenie/faraday)
  * And of course any library built on Net::HTTP, such as [Mechanize](http://github.com/tenderlove/mechanize),
    [HTTParty](http://github.com/jnunemaker/httparty) or [Rest Client](http://github.com/archiloque/rest-client).
* Request matching is configurable based on HTTP method, URI, host, path, body and headers, or you can easily
  implement a custom request matcher to handle any need.
* The same request can receive different responses in different tests--just use different cassettes.
* The recorded requests and responses are stored on disk in a serialization format of your choice
  (currently YAML and JSON are built in, and you can easily implement your own custom serializer)
  and can easily be inspected and edited.
* Dynamic responses are supported using ERB.
* Automatically re-records cassettes on a configurable regular interval to keep them fresh and current.
* Disables all HTTP requests that you don't explicitly allow.
* Simple cucumber integration is provided using tags.
* Includes convenient RSpec macro and integration with RSpec 2 metadata.
* Known to work well with many popular ruby libraries including RSpec 1 & 2, Cucumber, Test::Unit,
  Capybara, Mechanize, Rest-Client and HTTParty.
* Includes Rack and Faraday middleware.

## Usage

Browse the [documentation](http://relishapp.com/myronmarston/vcr) for usage info.

The [VCR talk given at Philly.rb](http://philly-rb-vcr-talk.heroku.com/) also
contains good usage info.

## Release Policy

VCR follows the principles of [semantic versioning](http://semver.org/).
The [cucumber features](http://relishapp.com/myronmarston/vcr) define
VCR's public API.  Patch level releases contain only bug fixes.  Minor
releases contain backward-compatible new features.  Major new releases
contain backwards-incompatible changes to the public API.

## Ruby Interpreter Compatibility

VCR has been tested on the following ruby interpreters:

* MRI 1.8.7
* MRI 1.9.2
* REE 1.8.7
* JRuby
* Rubinius

## Development

* Source hosted on [GitHub](http://github.com/myronmarston/vcr).
* Direct questions and discussions to the [mailing list](http://groups.google.com/group/vcr-ruby).
* Report issues on [GitHub Issues](http://github.com/myronmarston/vcr/issues).
* Pull requests are very welcome! Please include spec and/or feature coverage for every patch,
  and create a topic branch for every separate change you make.
* See the [Contributing](https://github.com/myronmarston/vcr/blob/master/CONTRIBUTING.md)
  guide for instructions on running the specs and features.
* Documentation is generated with [YARD](http://yardoc.org/) ([cheat sheet](http://cheat.errtheblog.com/s/yard/)).
  To generate while developing:

```
yard server --reload
```

If you find VCR useful, please recommend me on [working with rails](http://workingwithrails.com/person/16590-myron-marston).

## Thanks

* [Aslak Hellesøy](http://github.com/aslakhellesoy) for [Cucumber](http://github.com/aslakhellesoy/cucumber).
* [Bartosz Blimke](http://github.com/bblimke) for [WebMock](http://github.com/bblimke/webmock).
* [Chris Kampmeier](http://github.com/chrisk) for [FakeWeb](http://github.com/chrisk/fakeweb).
* [Chris Young](http://github.com/chrisyoung) for [NetRecorder](http://github.com/chrisyoung/netrecorder),
  the inspiration for VCR.
* [David Balatero](https://github.com/dbalatero) for help with [Typhoeus](https://github.com/pauldix/typhoeus)
  support.
* [Wesley Beary](https://github.com/geemus) for help with [Excon](https://github.com/geemus/excon)
  support.

Thanks also to the following people who have contributed patches or helpful suggestions:

* [Aaron Brethorst](http://github.com/aaronbrethorst)
* [Avdi Grimm](https://github.com/avdi)
* [Bartosz Blimke](http://github.com/bblimke)
* [Benjamin Oakes](https://github.com/benjaminoakes)
* [Ben Hutton](http://github.com/benhutton)
* [Bradley Isotope](https://github.com/bradleyisotope)
* [Carlos Kirkconnell](https://github.com/kirkconnell)
* [Eric Allam](http://github.com/rubymaverick)
* [Flaviu Simihaian](https://github.com/closedbracket)
* [Justin Smestad](https://github.com/jsmestad)
* [Karl Baum](https://github.com/kbaum)
* [Michael Lavrisha](https://github.com/vrish88)
* [Nathaniel Bibler](https://github.com/nbibler)
* [Oliver Searle-Barnes](https://github.com/opsb)
* [Paco Guzmán](https://github.com/pacoguzman)
* [Ryan Bates](https://github.com/ryanb)
* [Sathya Sekaran](https://github.com/sfsekaran)
* [Wesley Beary](https://github.com/geemus)

## Similar Libraries

* [Betamax](https://github.com/robfletcher/betamax) (Groovy)
* [Ephemeral Response](https://github.com/sandro/ephemeral_response) (Ruby)
* [Mimic](https://github.com/acoulton/mimic) (PHP/Kohana)
* [Net::HTTP Spy](http://github.com/martinbtt/net-http-spy) (Ruby)
* [NetRecorder](https://github.com/chrisyoung/netrecorder) (Ruby)
* [Stale Fish](https://github.com/jsmestad/stale_fish) (Ruby)
* [WebFixtures](http://github.com/trydionel/web_fixtures) (Ruby)

## Copyright

Copyright (c) 2010-2011 Myron Marston. See LICENSE for details.
