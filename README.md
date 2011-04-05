# VCR [![Build Status](http://travis-ci.org/myronmarston/vcr.png)](http://travis-ci.org/myronmarston/vcr)

Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.

## Synopsis

    require 'rubygems'
    require 'test/unit'
    require 'vcr'

    VCR.config do |c|
      c.cassette_library_dir = 'fixtures/vcr_cassettes'
      c.stub_with :webmock # or :fakeweb
    end

    class VCRTest < Test::Unit::TestCase
      def test_example_dot_com
        VCR.use_cassette('synopsis') do
          response = Net::HTTP.get_response(URI('http://www.iana.org/domains/example/'))
          assert_match /Example Domains/, response.body
        end
      end
    end

Run this test once, and VCR will record the http request to `fixtures/vcr_cassettes/synopsis.yml`.  Run it again, and VCR
will replay the response from example.com when the http request is made.  This test is now fast (no real HTTP requests are
made anymore), deterministic (the test will continue to pass, even if you are offline, or example.com goes down for
maintenance) and accurate (the response from example.com will contain the same headers and body you get from a real request).

## Features

* Automatically records and replays your HTTP interactions with minimal setup/configuration code.
* Supports and works with the HTTP stubbing facilities of multiple libraries.  Currently, the
  following are supported:
  * [FakeWeb](https://github.com/chrisk/fakeweb)
  * [WebMock](https://github.com/bblimke/webmock)
  * [Typhoeus](https://github.com/dbalatero/typhoeus)
  * [Faraday](https://github.com/technoweenie/faraday)
* Supports multiple HTTP libraries:
  * [Patron](http://github.com/toland/patron) (when using WebMock)
  * [Curb](http://github.com/taf2/curb) (when using WebMock -- only supports Curb::Easy at the moment)
  * [HTTPClient](http://github.com/nahi/httpclient) (when using WebMock)
  * [em-http-request](http://github.com/igrigorik/em-http-request) (when using WebMock)
  * [Net::HTTP](http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html) (when using FakeWeb and WebMock)
  * [Typhoeus](https://github.com/dbalatero/typhoeus) (Typhoeus::Hydra, but not Typhoeus::Easy or Typhoeus::Multi)
  * [Faraday](https://github.com/technoweenie/faraday)
  * And of course any library built on Net::HTTP, such as [Mechanize](http://github.com/tenderlove/mechanize),
    [HTTParty](http://github.com/jnunemaker/httparty) or [Rest Client](http://github.com/archiloque/rest-client).
* Request matching is configurable based on HTTP method, URI, host, path, body and headers.
* The same request can receive different responses in different tests--just use different cassettes.
* The recorded requests and responses are stored on disk as YAML and can easily be inspected and edited.
* Dynamic responses are supported using ERB.
* Automatically re-records cassettes on a configurable regular interval to keep them fresh and current.
* Disables all HTTP requests that you don't explicitly allow.
* Simple cucumber integration is provided using tags.
* Includes convenient RSpec macro.
* Known to work well with many popular ruby libraries including RSpec 1 & 2, Cucumber, Test::Unit,
  Capybara, Mechanize, Rest-Client and HTTParty.
* Extensively tested on 7 different ruby interpretters.
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

* MRI 1.8.6
* MRI 1.8.7
* MRI 1.9.1
* MRI 1.9.2
* REE 1.8.7
* JRuby 1.5.6
* Rubinius 1.2.1

## Known Issues

* VCR uses YAML to serialize the HTTP interactions to disk in a
  human-readable, human-editable format.  Unfortunately there are bugs
  in Syck, Ruby's default YAML engine, that cause it to modify strings
  when serializing them.  It appears the the bug is limited to entire
  lines of whitespace.  A string such as `"1\n \n2"` will get changed
  to `"1\n\n2"` (see [this gist](https://gist.github.com/815754) for
  example code).  In practice, this usually isn't so bad, but it can
  occassionally cause problems, especially when the recorded
  response includes a `content_length` header and you are using an
  HTTP client that relies on this.  Mechanize will raise an `EOFError`
  when the `content_length` header does not match the response body
  length.  One solution is to use Psych, the new YAML engine included
  in Ruby 1.9.  VCR attempts to use Psych if possible, but you may have
  to [re-compile ruby 1.9](http://rhnh.net/2011/01/31/psych-yaml-in-ruby-1-9-2-with-rvm-and-snow-leopard-osx)
  to use it.  See [this issue](https://github.com/myronmarston/vcr/issues#issue/43)
  for more info.  You can also use the `:update_content_length_header`
  cassette option to ensure the header has the correct value.

## Development

* Source hosted on [GitHub](http://github.com/myronmarston/vcr).
* Direct questions and discussions to the [mailing list](http://groups.google.com/group/vcr-ruby).
* Report issues on [GitHub Issues](http://github.com/myronmarston/vcr/issues).
* Pull requests are very welcome! Please include spec and/or feature coverage for every patch,
  and create a topic branch for every separate change you make.

If you find VCR useful, please recommend me on [working with rails](http://workingwithrails.com/person/16590-myron-marston).

## Thanks

* [Aslak Hellesøy](http://github.com/aslakhellesoy) for [Cucumber](http://github.com/aslakhellesoy/cucumber).
* [Bartosz Blimke](http://github.com/bblimke) for [WebMock](http://github.com/bblimke/webmock).
* [Chris Kampmeier](http://github.com/chrisk) for [FakeWeb](http://github.com/chrisk/fakeweb).
* [Chris Young](http://github.com/chrisyoung) for [NetRecorder](http://github.com/chrisyoung/netrecorder),
  the inspiration for VCR.
* [David Balatero](https://github.com/dbalatero) for help with [Typhoeus](https://github.com/pauldix/typhoeus)
  support.

Thanks also to the following people who have contributed patches or helpful suggestions:

* [Aaron Brethorst](http://github.com/aaronbrethorst)
* [Bartosz Blimke](http://github.com/bblimke)
* [Ben Hutton](http://github.com/benhutton)
* [Eric Allam](http://github.com/rubymaverick)
* [Karl Baum](https://github.com/kbaum)
* [Nathaniel Bibler](https://github.com/nbibler)
* [Oliver Searle-Barnes](https://github.com/opsb)

## Copyright

Copyright (c) 2010-2011 Myron Marston. See LICENSE for details.
