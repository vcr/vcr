# VCR

Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.

## Synopsis

    require 'test/unit'
    require 'vcr'

    VCR.config do |c|
      c.cassette_library_dir = 'fixtures/vcr_cassettes'
      c.stub_with :webmock # or :fakeweb
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
* Supports multiple HTTP libraries:
  * [Patron](http://github.com/toland/patron) (WebMock)
  * [Curb](http://github.com/taf2/curb) (WebMock)
  * [HTTPClient](http://github.com/nahi/httpclient) (WebMock)
  * [em-http-request](http://github.com/igrigorik/em-http-request) (WebMock)
  * [Net::HTTP](http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html) (FakeWeb and WebMock)
  * [Typhoeus](https://github.com/pauldix/typhoeus)
  * And of course any library built on Net::HTTP, such as [Mechanize](http://github.com/tenderlove/mechanize),
    [HTTParty](http://github.com/jnunemaker/httparty) or [Rest Client](http://github.com/archiloque/rest-client).
* Request matching is configurable based on HTTP method, URI, host, path, body and headers.
* The same request can receive different responses in different tests--just use different cassettes.
* The recorded requests and responses are stored on disk as YAML and can easily be inspected and edited.
* Dynamic responses are supported using ERB.
* Automatically re-records cassettes on a configurable regular interval to keep them fresh and current.
* Disables all HTTP requests that you don't explicitly allow.
* Simple cucumber integration is provided using tags.
* Known to work well with many popular ruby libraries including RSpec 1 & 2, Cucumber, Test::Unit,
  Capybara, Mechanize, Rest-Client and HTTParty.
* Extensively tested on 7 different ruby interpretters.

## Usage

Browse the [cucumber features](http://relishapp.com/myronmarston/vcr) or visit
the [wiki](http://github.com/myronmarston/vcr/wiki) for usage info and
documentation.

The [VCR talk given at Philly.rb](http://philly-rb-vcr-talk.heroku.com/) also
contains good usage info.

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

## Copyright

Copyright (c) 2010 Myron Marston. See LICENSE for details.
