vcr
===

[![CI status](https://github.com/vcr/vcr/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/vcr/vcr/actions/workflows/test.yml)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/vcr/vcr.svg?style=flat-square)](http://github.com/vcr/vcr/releases)
[![Version](https://img.shields.io/gem/v/vcr.svg?style=flat-square)](https://rubygems.org/gems/vcr)
[![OpenCollective](https://opencollective.com/vcr/backers/badge.svg?style=flat-square)](https://opencollective.com/vcr#backer)
[![OpenCollective](https://opencollective.com/vcr/sponsors/badge.svg?style=flat-square)](https://opencollective.com/vcr#sponsor)


Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.

**Help Wanted**

We're looking for more maintainers. If you'd like to help maintain a well-used gem please spend some time reviewing pull requests, issues, or participating in discussions.

Usage
=====

``` ruby
require 'rubygems'
require 'test/unit'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

class VCRTest < Test::Unit::TestCase
  def test_example_dot_com
    VCR.use_cassette("synopsis") do
      response = Net::HTTP.get_response(URI('http://www.iana.org/domains/reserved'))
      assert_match /Example domains/, response.body
    end
  end
end
```

Run this test once, and VCR will record the HTTP request to `fixtures/vcr_cassettes/synopsis.yml`. Run it again, and VCR will replay the response from iana.org when the HTTP request is made. This test is now fast (no real HTTP requests are made anymore), deterministic (the test will continue to pass, even if you are offline, or iana.org goes down for maintenance) and accurate (the response will contain the same headers and body you get from a real request). You can use a different cassette library directory (e.g., "test/vcr_cassettes").

NOTE: To avoid storing any sensitive information in cassettes, check out [Filter Sensitive Data](https://relishapp.com/vcr/vcr/v/5-0-0/docs/configuration/filter-sensitive-data) in the documentation.

**Rails and Minitest:**
Do *not* use 'test/fixtures' as the directory if you're using Rails and Minitest (Rails will instead transitively load any files in that directory as models).

**Features**

  * Automatically records and replays your HTTP interactions with minimal setup/configuration code.
  * Supports and works with the HTTP stubbing facilities of multiple libraries. Currently, the following are supported:
    * [WebMock](https://github.com/bblimke/webmock)
    * [Typhoeus](https://github.com/typhoeus/typhoeus)
    * [Faraday](https://github.com/lostisland/faraday)
    * [Excon](https://github.com/excon/excon)
  * Supports multiple HTTP libraries:
    * [Patron](https://github.com/toland/patron) (when using WebMock)
    * [Curb](https://github.com/taf2/curb) (when using WebMock -- only supports Curl::Easy at the moment)
    * [HTTPClient](https://github.com/nahi/httpclient) (when using WebMock)
    * [em-http-request](https://github.com/igrigorik/em-http-request) (when using WebMock)
    * [Net::HTTP](http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html) (when using WebMock)
    * [Typhoeus](https://github.com/typhoeus/typhoeus) (Typhoeus::Hydra, but not Typhoeus::Easy or Typhoeus::Multi)
    * [Excon](https://github.com/geemus/excon)
    * [Faraday](https://github.com/lostisland/faraday)
    * And of course any library built on Net::HTTP, such as [Mechanize](https://github.com/sparklemotion/mechanize), [HTTParty](https://github.com/jnunemaker/httparty) or [Rest Client](https://github.com/rest-client/rest-client).
  * Request matching is configurable based on HTTP method, URI, host, path, body and headers, or you can easily implement a custom request matcher to handle any need.
  * The same request can receive different responses in different tests--just use different cassettes.
  * The recorded requests and responses are stored on disk in a serialization format of your choice (currently YAML and JSON are built in, and you can easily implement your own custom serializer) and can easily be inspected and edited.
  * Dynamic responses are supported using ERB.
  * Optionally re-records cassettes on a configurable regular interval to keep them fresh and current.
  * Disables all HTTP requests that you don't explicitly allow.
  * Simple Cucumber integration is provided using tags.
  * Includes convenient RSpec macros and integration with RSpec 2 metadata.
  * Known to work well with many popular Ruby libraries including RSpec 1 & 2, Cucumber, Test::Unit, Capybara, Mechanize, Rest Client and HTTParty.
  * Includes Rack and Faraday middleware.
  * Supports filtering sensitive data from the response body

The docs come in two flavors:

  * The [relish docs](https://relishapp.com/vcr/vcr/docs) contain example-based documentation (VCR's Cucumber suite, in fact). It's a good place to look when you are first getting started with VCR, or if you want to see an example of how to use a feature.
  * The [rubydoc.info docs](https://www.rubydoc.info/gems/vcr/frames) contain API documentation. The API docs contain detailed info about all of VCR's public API.
  * See the [CHANGELOG](https://github.com/vcr/vcr/blob/master/CHANGELOG.md) doc for info about what's new and changed.

There is also a Railscast (from 2011), which will get you up and running in no-time http://railscasts.com/episodes/291-testing-with-vcr.

**Release Policy**

VCR follows the principles of [semantic versioning](https://semver.org/). The [API documentation](https://rubydoc.info/gems/vcr/frames) defines VCR's public API. Patch level releases contain only bug fixes. Minor releases contain backward-compatible new features. Major new releases contain backwards-incompatible changes to the public API.

**Ruby Interpreter Compatibility**

VCR versions 6.x are tested on the following ruby interpreters:

  * MRI 3.1
  * MRI 3.0
  * MRI 2.7
  * MRI 2.6

[VCR 6.0.0](https://github.com/vcr/vcr/releases/tag/v6.0.0) is the last version supporting >= 2.4. Upcoming releases will only explicitly support >= 2.6.

**Development**

  * Source hosted on [GitHub](https://github.com/vcr/vcr).
  * Direct questions and discussions on [GitHub Issues](https://github.com/vcr/vcr/issues).
  * Report bugs/issues on [GitHub Issues](https://github.com/vcr/vcr/issues).
  * Pull requests are very welcome! Please include spec and/or feature coverage for every patch,
    and create a topic branch for every separate change you make.
  * See the [Contributing](https://github.com/vcr/vcr/blob/master/CONTRIBUTING.md)
    guide for instructions on running the specs and features.
  * Code quality metrics are checked by [Code Climate](https://codeclimate.com/github/vcr/vcr).
  * Documentation is generated with [YARD](https://yardoc.org/) ([cheat sheet](https://rubydoc.info/gems/yard/file/docs/GettingStarted.md)).
    To generate while developing:

```
yard server --reload
```

**Ports in Other Languages**

  * [Betamax](https://github.com/sigmavirus24/betamax) (Python)
  * [VCR.py](https://github.com/kevin1024/vcrpy) (Python)
  * [Betamax](https://github.com/thegreatape/betamax) (Go)
  * [DVR](https://github.com/orchestrate-io/dvr) (Go)
  * [Go VCR](https://github.com/dnaeon/go-vcr) (Go)
  * [Betamax](https://github.com/wjlroe/betamax) (Clojure)
  * [vcr-clj](https://github.com/ifesdjeen/vcr-clj) (Clojure)
  * [scotch](https://github.com/mleech/scotch) (C#/.NET)
  * [Betamax.NET](https://github.com/mfloryan/Betamax.Net) (C#/.NET)
  * [ExVCR](https://github.com/parroty/exvcr) (Elixir)
  * [HAVCR](https://github.com/cordawyn/havcr) (Haskell)
  * [Mimic](https://github.com/acoulton/mimic) (PHP/Kohana)
  * [PHP-VCR](https://github.com/php-vcr/php-vcr) (PHP)
  * [Talkback](https://github.com/ijpiantanida/talkback) (JavaScript/Node)
  * [NSURLConnectionVCR](https://bitbucket.org/martijnthe/nsurlconnectionvcr) (Objective-C)
  * [VCRURLConnection](https://github.com/dstnbrkr/VCRURLConnection) (Objective-C)
  * [DVR](https://github.com/venmo/DVR) (Swift)
  * [VHS](https://github.com/diegoeche/vhs) (Erlang)
  * [Betamax](https://github.com/betamaxteam/betamax) (Java)
  * [http_replayer](https://github.com/ucarion/http_replayer) (Rust)
  * [OkReplay](https://github.com/airbnb/okreplay) (Java/Android)
  * [vcr](https://github.com/ropensci/vcr) (R)

**Related Projects**

  * [Mr. Video](https://github.com/quidproquo/mr_video) (Rails engine for managing VCR cassettes and episodes)


**Similar Libraries in Ruby**

  * [Ephemeral Response](https://github.com/sandro/ephemeral_response)
  * [Net::HTTP Spy](https://github.com/martinbtt/net-http-spy)
  * [NetRecorder](https://github.com/chrisyoung/netrecorder)
  * [Puffing Billy](https://github.com/oesmith/puffing-billy)
  * [REST-assured](https://github.com/artemave/REST-assured)
  * [Stale Fish](https://github.com/jsmestad/stale_fish)
  * [WebFixtures](https://github.com/trydionel/web_fixtures)


Credits
=======

  * [Aslak Hellesøy](https://github.com/aslakhellesoy) for [Cucumber](https://github.com/aslakhellesoy/cucumber).
  * [Bartosz Blimke](https://github.com/bblimke) for [WebMock](https://github.com/bblimke/webmock).
  * [Chris Kampmeier](https://github.com/chrisk) for [FakeWeb](https://github.com/chrisk/fakeweb).
  * [Chris Young](https://github.com/chrisyoung) for [NetRecorder](https://github.com/chrisyoung/netrecorder),
    the inspiration for VCR.
  * [David Balatero](https://github.com/dbalatero) and [Hans Hasselberg](https://github.com/i0rek)
    for help with [Typhoeus](https://github.com/typhoeus/typhoeus) support.
  * [Wesley Beary](https://github.com/geemus) for help with [Excon](https://github.com/geemus/excon)
    support.
  * [Jacob Green](https://github.com/Jacobkg) for help with ongoing VCR
    maintenance.
  * [Jan Berdajs](https://github.com/mrbrdo) and [Daniel Berger](https://github.com/djberg96)
    for improvements to thread-safety.


Thanks also to the following people who have contributed patches or helpful suggestions:

  * [Aaron Brethorst](https://github.com/aaronbrethorst)
  * [Alexander Wenzowski](https://github.com/wenzowski)
  * [Austen Ito](https://github.com/austenito)
  * [Avdi Grimm](https://github.com/avdi)
  * [Bartosz Blimke](http://github.com/bblimke)
  * [Benjamin Oakes](https://github.com/benjaminoakes)
  * [Ben Hutton](https://github.com/benhutton)
  * [Bradley Isotope](https://github.com/bradleyisotope)
  * [Carlos Kirkconnell](https://github.com/kirkconnell)
  * [Chad Jolly](https://github.com/cjolly)
  * [Chris Le](https://github.com/chrisle)
  * [Chris Gunther](https://github.com/cgunther)
  * [Eduardo Maia](https://github.com/emaiax)
  * [Eric Allam](https://github.com/rubymaverick)
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


# Backers

Support us with a monthly donation and help us continue our activities. [[Become a backer](https://opencollective.com/vcr#backer)]

<a href="https://opencollective.com/vcr/backer/0/website" target="_blank"><img src="https://opencollective.com/vcr/backer/0/avatar"></a>
<a href="https://opencollective.com/vcr/backer/1/website" target="_blank"><img src="https://opencollective.com/vcr/backer/1/avatar"></a>
<a href="https://opencollective.com/vcr/backer/2/website" target="_blank"><img src="https://opencollective.com/vcr/backer/2/avatar"></a>
<a href="https://opencollective.com/vcr/backer/3/website" target="_blank"><img src="https://opencollective.com/vcr/backer/3/avatar"></a>
<a href="https://opencollective.com/vcr/backer/4/website" target="_blank"><img src="https://opencollective.com/vcr/backer/4/avatar"></a>
<a href="https://opencollective.com/vcr/backer/5/website" target="_blank"><img src="https://opencollective.com/vcr/backer/5/avatar"></a>
<a href="https://opencollective.com/vcr/backer/6/website" target="_blank"><img src="https://opencollective.com/vcr/backer/6/avatar"></a>
<a href="https://opencollective.com/vcr/backer/7/website" target="_blank"><img src="https://opencollective.com/vcr/backer/7/avatar"></a>
<a href="https://opencollective.com/vcr/backer/8/website" target="_blank"><img src="https://opencollective.com/vcr/backer/8/avatar"></a>
<a href="https://opencollective.com/vcr/backer/9/website" target="_blank"><img src="https://opencollective.com/vcr/backer/9/avatar"></a>
<a href="https://opencollective.com/vcr/backer/10/website" target="_blank"><img src="https://opencollective.com/vcr/backer/10/avatar"></a>
<a href="https://opencollective.com/vcr/backer/11/website" target="_blank"><img src="https://opencollective.com/vcr/backer/11/avatar"></a>
<a href="https://opencollective.com/vcr/backer/12/website" target="_blank"><img src="https://opencollective.com/vcr/backer/12/avatar"></a>
<a href="https://opencollective.com/vcr/backer/13/website" target="_blank"><img src="https://opencollective.com/vcr/backer/13/avatar"></a>
<a href="https://opencollective.com/vcr/backer/14/website" target="_blank"><img src="https://opencollective.com/vcr/backer/14/avatar"></a>
<a href="https://opencollective.com/vcr/backer/15/website" target="_blank"><img src="https://opencollective.com/vcr/backer/15/avatar"></a>
<a href="https://opencollective.com/vcr/backer/16/website" target="_blank"><img src="https://opencollective.com/vcr/backer/16/avatar"></a>
<a href="https://opencollective.com/vcr/backer/17/website" target="_blank"><img src="https://opencollective.com/vcr/backer/17/avatar"></a>
<a href="https://opencollective.com/vcr/backer/18/website" target="_blank"><img src="https://opencollective.com/vcr/backer/18/avatar"></a>
<a href="https://opencollective.com/vcr/backer/19/website" target="_blank"><img src="https://opencollective.com/vcr/backer/19/avatar"></a>
<a href="https://opencollective.com/vcr/backer/20/website" target="_blank"><img src="https://opencollective.com/vcr/backer/20/avatar"></a>
<a href="https://opencollective.com/vcr/backer/21/website" target="_blank"><img src="https://opencollective.com/vcr/backer/21/avatar"></a>
<a href="https://opencollective.com/vcr/backer/22/website" target="_blank"><img src="https://opencollective.com/vcr/backer/22/avatar"></a>
<a href="https://opencollective.com/vcr/backer/23/website" target="_blank"><img src="https://opencollective.com/vcr/backer/23/avatar"></a>
<a href="https://opencollective.com/vcr/backer/24/website" target="_blank"><img src="https://opencollective.com/vcr/backer/24/avatar"></a>
<a href="https://opencollective.com/vcr/backer/25/website" target="_blank"><img src="https://opencollective.com/vcr/backer/25/avatar"></a>
<a href="https://opencollective.com/vcr/backer/26/website" target="_blank"><img src="https://opencollective.com/vcr/backer/26/avatar"></a>
<a href="https://opencollective.com/vcr/backer/27/website" target="_blank"><img src="https://opencollective.com/vcr/backer/27/avatar"></a>
<a href="https://opencollective.com/vcr/backer/28/website" target="_blank"><img src="https://opencollective.com/vcr/backer/28/avatar"></a>
<a href="https://opencollective.com/vcr/backer/29/website" target="_blank"><img src="https://opencollective.com/vcr/backer/29/avatar"></a>


# Sponsors

Become a sponsor and get your logo on our README on Github with a link to your site. [[Become a sponsor](https://opencollective.com/vcr#sponsor)]

<a href="https://opencollective.com/vcr/sponsor/0/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/0/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/1/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/1/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/2/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/2/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/3/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/3/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/4/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/4/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/5/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/5/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/6/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/6/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/7/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/7/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/8/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/8/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/9/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/9/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/10/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/10/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/11/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/11/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/12/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/12/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/13/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/13/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/14/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/14/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/15/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/15/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/16/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/16/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/17/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/17/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/18/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/18/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/19/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/19/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/20/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/20/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/21/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/21/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/22/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/22/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/23/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/23/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/24/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/24/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/25/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/25/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/26/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/26/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/27/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/27/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/28/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/28/avatar"></a>
<a href="https://opencollective.com/vcr/sponsor/29/website" target="_blank"><img src="https://opencollective.com/vcr/sponsor/29/avatar"></a>
