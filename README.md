# VCR

Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.

[![Gem Version](https://img.shields.io/gem/v/vcr.svg)](http://rubygems.org/gems/vcr) [![Build Status](https://img.shields.io/travis/vcr/vcr/master.svg)](https://travis-ci.org/vcr/vcr) [![Code Climate](https://img.shields.io/codeclimate/github/vcr/vcr.svg)](https://codeclimate.com/github/vcr/vcr)

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
      response = Net::HTTP.get_response(URI('http://www.iana.org/domains/reserved'))
      assert_match /Example domains/, response.body
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
  * [WebMock](https://github.com/bblimke/webmock)
  * [Typhoeus](https://github.com/typhoeus/typhoeus)
  * [Faraday](https://github.com/lostisland/faraday)
  * [Excon](https://github.com/geemus/excon)
  * [FakeWeb](https://github.com/chrisk/fakeweb) (deprecated)
* Supports multiple HTTP libraries:
  * [Patron](http://github.com/toland/patron) (when using WebMock)
  * [Curb](http://github.com/taf2/curb) (when using WebMock -- only supports Curl::Easy at the moment)
  * [HTTPClient](http://github.com/nahi/httpclient) (when using WebMock)
  * [em-http-request](http://github.com/igrigorik/em-http-request) (when using WebMock)
  * [Net::HTTP](http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html) (when using FakeWeb and WebMock)
  * [Typhoeus](https://github.com/typhoeus/typhoeus) (Typhoeus::Hydra, but not Typhoeus::Easy or Typhoeus::Multi)
  * [Excon](https://github.com/geemus/excon)
  * [Faraday](https://github.com/lostisland/faraday)
  * And of course any library built on Net::HTTP, such as [Mechanize](http://github.com/sparklemotion/mechanize),
    [HTTParty](http://github.com/jnunemaker/httparty) or [Rest Client](http://github.com/rest-client/rest-client).
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

The docs come in two flavors:

* The [relish docs](https://relishapp.com/vcr/vcr/docs) contain
  example-based documentation (VCR's cucumber suite, in fact). It's a
  good place to look when you are first getting started with VCR, or if
  you want to see an example of how to use a feature.
* The [rubydoc.info docs](http://rubydoc.info/gems/vcr/frames) contain
  API documentation. The API docs contain detailed info about all of VCR's
  public API.

See the [Upgrade](https://github.com/vcr/vcr/blob/master/Upgrade.md) doc
for info about what's new and changed in VCR 2.0.

There is also a Railscast, which will get you up and running in no-time http://railscasts.com/episodes/291-testing-with-vcr

## Release Policy

VCR follows the principles of [semantic versioning](http://semver.org/).
The [API documentation](http://rubydoc.info/gems/vcr/frames) define
VCR's public API.  Patch level releases contain only bug fixes.  Minor
releases contain backward-compatible new features.  Major new releases
contain backwards-incompatible changes to the public API.

## Ruby Interpreter Compatibility

VCR has been tested on the following ruby interpreters:

* MRI 1.8.7
* MRI 1.9.2
* MRI 1.9.3
* MRI 2.0.0
* REE 1.8.7
* JRuby
* Rubinius

Note that as of VCR 2, 1.8.6 and 1.9.1 are not supported.

## Development

* Source hosted on [GitHub](http://github.com/vcr/vcr).
* Direct questions and discussions to the [IRC channel](irc://irc.freenode.net/vcr) or
  the [mailing list](http://groups.google.com/group/vcr-ruby).
* Report issues on [GitHub Issues](http://github.com/vcr/vcr/issues).
* Pull requests are very welcome! Please include spec and/or feature coverage for every patch,
  and create a topic branch for every separate change you make.
* See the [Contributing](https://github.com/vcr/vcr/blob/master/CONTRIBUTING.md)
  guide for instructions on running the specs and features.
* Code quality metrics are checked by [Code Climate](https://codeclimate.com/github/vcr/vcr).
* Documentation is generated with [YARD](http://yardoc.org/) ([cheat sheet](http://cheat.errtheblog.com/s/yard)).
  To generate while developing:

```
yard server --reload
```

## Thanks

* [Aslak Hellesøy](http://github.com/aslakhellesoy) for [Cucumber](http://github.com/aslakhellesoy/cucumber).
* [Bartosz Blimke](http://github.com/bblimke) for [WebMock](http://github.com/bblimke/webmock).
* [Chris Kampmeier](http://github.com/chrisk) for [FakeWeb](http://github.com/chrisk/fakeweb).
* [Chris Young](http://github.com/chrisyoung) for [NetRecorder](http://github.com/chrisyoung/netrecorder),
  the inspiration for VCR.
* [David Balatero](https://github.com/dbalatero) and [Hans Hasselberg](https://github.com/i0rek)
  for help with [Typhoeus](https://github.com/typhoeus/typhoeus) support.
* [Wesley Beary](https://github.com/geemus) for help with [Excon](https://github.com/geemus/excon)
  support.
* [Jacob Green](https://github.com/Jacobkg) for help with ongoing VCR
  maintenance.

Thanks also to the following people who have contributed patches or helpful suggestions:

* [Aaron Brethorst](http://github.com/aaronbrethorst)
* [Alexander Wenzowski](https://github.com/wenzowski)
* [Austen Ito](https://github.com/austenito)
* [Avdi Grimm](https://github.com/avdi)
* [Bartosz Blimke](http://github.com/bblimke)
* [Benjamin Oakes](https://github.com/benjaminoakes)
* [Ben Hutton](http://github.com/benhutton)
* [Bradley Isotope](https://github.com/bradleyisotope)
* [Carlos Kirkconnell](https://github.com/kirkconnell)
* [Chad Jolly](https://github.com/cjolly)
* [Chris Le](https://github.com/chrisle)
* [Chris Gunther](https://github.com/cgunther)
* [Eduardo Maia](https://github.com/emaiax)
* [Eric Allam](http://github.com/rubymaverick)
* [Ezekiel Templin](https://github.com/ezkl)
* [Flaviu Simihaian](https://github.com/closedbracket)
* [Gordon Wilson](https://github.com/gordoncww)
* [Hans Hasselberg](https://github.com/i0rek)
* [Herman Verschooten](https://github.com/Hermanverschooten)
* [Ian Cordasco](https://github.com/sigmavirus24)
* [Ingemar](https://github.com/ingemar)
* [Ilya Scharrenbroich](https://github.com/quidproquo)
* [Jacob Green](https://github.com/Jacobkg)
* [James Bence](https://github.com/jbence)
* [Jay Shepherd](https://github.com/jayshepherd)
* [Jeff Pollard](https://github.com/Fluxx)
* [Joe Nelson](https://github.com/begriffs)
* [Jonathan Tron](https://github.com/JonathanTron)
* [Justin Smestad](https://github.com/jsmestad)
* [Karl Baum](https://github.com/kbaum)
* [Kris Luminar](https://github.com/kris-luminar)
* [Kurt Funai](https://github.com/kurtfunai)
* [Luke van der Hoeven](https://github.com/plukevdh)
* [Mark Burns](https://github.com/markburns)
* [Max Riveiro](https://github.com/kavu)
* [Michael Lavrisha](https://github.com/vrish88)
* [Michiel de Mare](https://github.com/mdemare)
* [Mike Dalton](https://github.com/kcdragon)
* [Mislav Marohnić](https://github.com/mislav)
* [Nathaniel Bibler](https://github.com/nbibler)
* [Noah Davis](https://github.com/noahd1)
* [Oliver Searle-Barnes](https://github.com/opsb)
* [Omer Rauchwerger](https://github.com/rauchy)
* [Paco Guzmán](https://github.com/pacoguzman)
* [Paul Morgan](https://github.com/jumanjiman)
* [playupchris](https://github.com/playupchris)
* [Ron Smith](https://github.com/ronwsmith)
* [Ryan Bates](https://github.com/ryanb)
* [Ryan Burrows](https://github.com/rhburrows)
* [Ryan Castillo](https://github.com/rmcastil)
* [Sathya Sekaran](https://github.com/sfsekaran)
* [Scott Carleton](https://github.com/ScotterC)
* [Shay Frendt](https://github.com/shayfrendt)
* [Steve Faulkner](https://github.com/southpolesteve)
* [Stephen Anderson](https://github.com/bendycode)
* [Todd Lunter](https://github.com/tlunter)
* [Tyler Hunt](https://github.com/tylerhunt)
* [Uģis Ozols](https://github.com/ugisozols)
* [vzvu3k6k](https://github.com/vzvu3k6k)
* [Wesley Beary](https://github.com/geemus)

## Ports in other languages

* [Betamax](https://github.com/robfletcher/betamax) (Groovy/JVM)
* [Betamax](https://github.com/sigmavirus24/betamax) (Python)
* [Betamax](https://github.com/thegreatape/betamax) (Go)
* [Betamax](https://github.com/wjlroe/betamax) (Clojure)
* [Betamax.NET](https://github.com/mfloryan/Betamax.Net) (C#/.NET)
* [ExVCR](https://github.com/parroty/exvcr) (Elixir)
* [HAVCR](https://github.com/cordawyn/havcr) (Haskell)
* [Mimic](https://github.com/acoulton/mimic) (PHP/Kohana)
* [Nock-VCR](https://github.com/carbonfive/nock-vcr) (JavaScript/Node)
* [NSURLConnectionVCR](https://bitbucket.org/martijnthe/nsurlconnectionvcr) (Objective-C)
* [PHP-VCR](https://github.com/php-vcr/php-vcr) (PHP)
* [Sepia](https://github.com/linkedin/sepia) (Javascript/Node)
* [TapeDeck.js](https://github.com/EndangeredMassa/TapeDeck.js) (JavaScript)
* [VCR.js](https://github.com/elcuervo/vcr.js) (JavaScript)
* [VCR.py](https://github.com/kevin1024/vcrpy) (Python)
* [VCRURLConnection](https://github.com/dstnbrkr/VCRURLConnection) (Objective-C)
* [vcr-clj](https://github.com/ifesdjeen/vcr-clj) (Clojure)
* [VHS](https://github.com/diegoeche/vhs) (Erlang)

## Related Projects

* [Mr. Video](https://github.com/quidproquo/mr_video) (Rails engine for managing VCR cassettes and episodes)


## Similar Libraries in Ruby

* [Ephemeral Response](https://github.com/sandro/ephemeral_response)
* [Net::HTTP Spy](http://github.com/martinbtt/net-http-spy)
* [NetRecorder](https://github.com/chrisyoung/netrecorder)
* [Puffing Billy](https://github.com/oesmith/puffing-billy)
* [REST-assured](https://github.com/artemave/REST-assured)
* [Stale Fish](https://github.com/jsmestad/stale_fish)
* [WebFixtures](http://github.com/trydionel/web_fixtures)

## Copyright

Copyright (c) 2010-2014 Myron Marston. Released under the terms of the
MIT license. See LICENSE for details.
