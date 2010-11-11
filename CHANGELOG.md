# Changelog

## 1.3.0 (November 11, 2010)

[Full Changelog](http://github.com/myronmarston/vcr/compare/v1.2.0...v.1.3.0)

* Moved documentation from README to [Wiki](http://github.com/myronmarston/vcr/wiki).
* Refactoring and code cleanup.
* Fix InternetConnection.available? so that it memoizes correctly when a connection is not available.
* Fix WebMock version checking to allow newly released 1.5.0 to be used without a warning.
* Add support for [Typhoeus](https://github.com/pauldix/typhoeus).  Thanks to
  [David Balatero](https://github.com/dbalatero) for making the necessary changes in Typhoeus
  to support VCR.

## 1.2.0 (October 13, 2010)

[Full Changelog](http://github.com/myronmarston/vcr/compare/v1.1.2...v1.2.0)

* Improved the `:all` record mode so that it keeps previously recorded interactions that do not match the
  new recorded interactions.  Previously, all of the previously recorded interactions were deleted.
* Added `:re_record_interval` cassette option.  This option causes a cassette to be re-recorded when the
  existing file is older than the specified interval.
* Improved RSpec support.  Added #use_vcr_cassette RSpec macro method that sets up a cassette for an RSpec
  example group.
* Fixed VCR/Net::HTTP/WebMock integration so that VCR no longer loads its Net::HTTP monkey patch when
  WebMock is used, and relies upon WebMock's after_request callback to record Net::HTTP instead.  This
  fixes [a bug](http://github.com/myronmarston/vcr/issues/14) when using WebMock and Open URI.
* Consider 0.0.0.0 to be a localhost alias (previously only "localhost" and 127.0.0.1 were considered).
* Added spec and feature coverage for Curb integration.  Works out of the box with no changes required
  to VCR due to [Pete Higgins'](http://github.com/phiggins) great work to add Curb support to WebMock.
* Got specs and features to pass on rubinius.
* Changed WebMock version requirement to 1.4.0.

## 1.1.2 (September 9, 2010)

[Full Changelog](http://github.com/myronmarston/vcr/compare/v1.1.1...v1.1.2)

* Fixed a minor bug with the WebMock integration: WebMock extends each `Net::HTTPResponse` with an extension
  module after reading the body, and VCR was doing the same thing, leading to some slight deviance from
  standard Net::HTTP behavior.  The fix prevents VCR from adding the same extension to a `Net::HTTPResponse`
  that has already been extende by WebMock.
* Fixed a minor bug in the `VCR::Net::HTTPResponse` module so that it correctly handles nil bodies (such as
  for a HEAD request).
* Refactored `VCR::Net::HTTPResponse` module so it is implemented in a much simpler manner.
* Updated specs and features so they pass against the latest WebMock release (1.3.5).
* Minor documentation updates.

## 1.1.1 (August 26, 2010)

[Full Changelog](http://github.com/myronmarston/vcr/compare/v1.1.0...v1.1.1)

* Updated to use and require FakeWeb 1.3.0. It includes a fix for a bug related to multiple values for the
  same response header.
* Use new `FakeWeb::Utility.request_uri_as_string` method rather than our own logic to construct a request uri.
* Use new `FakeWeb.allow_net_connect = /url regex/` feature to power the `ignore_localhost` VCR option rather
  then toggling `FakeWeb.allow_net_connect` in our Net::HTTP extension.
* Optimized `VCR.http_stubbing_adapter.stub_requests` a bit.
* Changed the http stubbing adapters to be modules rather than classes.  They should never be instantiated and
  don't really hold state, so a module is more appropriate.
* Warn when FakeWeb or WebMock are a minor or major version number ahead of the required version, as the new
  version isn't known to work with VCR.

## 1.1.0 (August 22, 2010)

[Full Changelog](http://github.com/myronmarston/vcr/compare/v1.0.3...v1.1.0)

* Added `:match_requests_on` cassette option, which determines how VCR matches requests.
* Removed VCR::TaskRunner and the corresponding rake task definition.  The rake task migrated cassettes from the
  0.3.1 format to the 0.4+ format.  If you are still on 0.3.1 or earlier, I recommend you upgrade to 0.4.1 first,
  migrate your cassettes and deal with migration warnings, then upgrade to the current release.
* Added some code to VCR::Cassette.new to check the options passed to the cassette and raise an error if any
  invalid options are passed.
* Optimized ERB rendering a bit.  Rather than creating a new struct subclass for each time we render an ERB
  cassette with locals, we keep a cache of reusable struct subclasses based on the desired attributes.
  [Benchmarking](http://gist.github.com/512948) reveals this is about 28% faster.
* Upgraded tests to use em-http-request 0.2.10 rather than 0.2.7.

## 1.0.3 (August 5, 2010)

[Full Changelog](http://github.com/myronmarston/vcr/compare/v1.0.2...v1.0.3)

* Upgraded VCR specs to RSpec 2.
* Updated `VCR::CucumberTags` so that it uses an `around` hook rather than a `before` hook and an `after` hook.
  Around hooks were added to Cucumber in the 0.7.3 release, so you'll have to be on that version or higher to use
  the `VCR::CucumberTags` feature.
* Updated the WebMock version requirement to 1.3.3 or greater.  1.3.2 and earlier versions did not properly handle
  multiple value for the same response header.
* Miscellaneous documentation updates.

## 1.0.2 (July 6, 2010)

[Full Changelog](http://github.com/myronmarston/vcr/compare/v1.0.1...v1.0.2)

* Fixed VCR to work with [rest-client](http://github.com/archiloque/rest-client).  Rest-client extends the Net::HTTP
  response body string with a module containing additional data, which got serialized to the cassette file YAML
  and occasionally caused problems when the YAML was deserialized.  Bug reported by
  [Thibaud Guillaume-Gentil](http://github.com/thibaudgg).
* Setup bundler to manage development dependencies.

## 1.0.1 (July 1, 2010)

[Full Changelog](http://github.com/myronmarston/vcr/compare/v1.0.0...v1.0.1)

* Fixed specs and features so they pass on MRI 1.9.2-preview3 and JRuby 1.5.1.
* Normalized response and request headers so that they are stored the same (i.e. lower case keys, arrays of values)
  in the cassette yaml files, regardless of which HTTP library is used.  This is the same way Net::HTTP normalizes
  HTTP headers.
* Fixed `VCR.use_cassette` so that it doesn't eject a cassette if an exception occurs while inserting one.
* Fixed FakeWeb adapter so that it works for requests that use basic auth. Patch submitted by
  [Eric Allam](http://github.com/rubymaverick).

## 1.0.0 (June 22, 2010)

[Full Changelog](http://github.com/myronmarston/vcr/compare/v0.4.1...v1.0.0)

* New Features
  * Added support for [HTTPClient](http://github.com/nahi/httpclient), [Patron](http://github.com/toland/patron) and
    [em-http-request](http://github.com/igrigorik/em-http-request) when WebMock is used.  Any future http libraries
    WebMock supports should (theoretically, at least) work without any VCR code changes.  Thanks to 
    [Bartosz Blimke](http://github.com/bblimke) for adding the necessary code to WebMock to make this happen!
  * Added support for dynamic responses using ERB.  A cassette will be evaluated as ERB before the YAML
    is deserialized if you pass it an `:erb => true` option.  You can pass variables using
    `:erb => { :var1 => 'some value', :var2 => 'another value' }`.
  * Added `ignore_localhost` configuration setting, which defaults to false.  Setting it true does the following:
    * Localhost requests will proceed as normal.  The "Real HTTP connections are disabled" error will not occur.
    * Localhost requests will not be recorded.
    * Previously recorded localhost requests will not be replayed.
  * Exposed the version number:
    * `VCR.version`       => string (in the format "major.minor.patch")
    * `VCR.version.parts` => array of integers
    * `VCR.version.major` => integer
    * `VCR.version.minor` => integer
    * `VCR.version.patch` => integer
  * Added test coverage and documentation of using a regex for non-deterministic URLs (i.e. URLs that include
    a timestamp as a query parameter).  It turns out this feature worked before, and I just didn't realize it :).

* Breaking Changes
  * The `:allow_real_http => lambda { |uri| ... }` cassette option has been removed.  There was no way to get
    this to work with the newly supported http libraries without extensive monkeypatching, and it was mostly
    useful for localhost requests, which is more easily handled by the new `ignore_localhost` config setting.
  * Removed methods and options that had been previously deprecated.  If you're upgrading from an old version,
    I recommend upgrading to 0.4.1 first, deal with all the deprecation warnings, then upgrade to 1.0.0.

* Misc Changes:
  * Removed dependency on [jeweler](http://github.com/technicalpickles/jeweler).  Manage the gemspec by hand instead.
  * Removed some extensions that are no longer necessary.

## 0.4.1 May 11, 2010

[Full Changelog](http://github.com/myronmarston/vcr/compare/v0.4.0...v0.4.1)

* Fixed a bug: when `Net::HTTPResponse#read_body` was called after VCR had read the body to record a new request,
  it raised an error (`IOError: Net::HTTPResponse#read_body called twice`).  My fix extends Net::HTTPResponse
  so that it no longer raises this error.

## 0.4.0 April 28, 2010

[Full Changelog](http://github.com/myronmarston/vcr/compare/v0.3.1...v0.4.0)

* Added support for webmock.  All the fakeweb-specific code is now in an adapter (as is the webmock code).

* Changed the format of the VCR cassettes.  The old format was tied directly to Net::HTTP, but webmock supports
  other HTTP libraries and I plan to allow VCR to use them in the future.  Note that this is a breaking change--your
  old VCR cassettes from prior releases will not work with VCR 0.4.0.  However, VCR provides a rake task to assist
  you in migrating your cassettes to the new format.  Simply add `load 'vcr/tasks/vcr.rake'` to your project's Rakefile,
  and run:

    $ rake vcr:migrate_cassettes DIR=path/to/cassete/library/directory

* The new cassette format records more information about the request (i.e. the request headers and body), so that it
  can potentially be used with webmock in the future.

* Made most of `VCR::Cassette`'s methods private.  I had forgotten to make the methods private before, and most of them
  don't need to be exposed.

* Automatically disallow http connections using the appropriate setting of the http stubbing library (fakeweb or webmock).
  This relieves users from the need to set the option themselves, so they hopefully aren't using either fakeweb or webmock
  directly, making it much easier to switch between these.

* Change documentation from rdoc to markdown format.

* Lots of other refactoring.

## 0.3.1 April 10, 2010

[Full Changelog](http://github.com/myronmarston/vcr/compare/v0.3.0...v0.3.1)

* Fixed a bug: when `Net::HTTP#request` was called with a block that had a return statement, the response was not being recorded.

## 0.3.0 March 24, 2010

[Full Changelog](http://github.com/myronmarston/vcr/compare/v0.2.0...v0.3.0)

* Renamed a bunch of methods, replacing them with method names that more clearly fit the VCR/cassette metaphor:
  * `VCR.create_cassette!` => `VCR.insert_cassette`
  * `VCR.destroy_cassette!` => `VCR.eject_cassette`
  * `VCR.with_cassette` => `VCR.use_cassette`
  * `VCR::Cassette#destroy!` => `VCR::Cassette#eject`
  * `VCR::Cassette#cache_file` => `VCR::Cassette#file`
  * `VCR::Config.cache_dir` => `VCR::Config.cassette_library_dir`
  * `:unregistered` record mode => `:new_episodes` record mode

* All the old methods still work, but you'll get deprecation warnings.

## 0.2.0 March 9, 2010

[Full Changelog](http://github.com/myronmarston/vcr/compare/v0.1.2...v0.2.0)

* Added `:allow_real_http` cassette option, which allows VCR to work with capybara and a javascript driver.
  Bug reported by [Ben Hutton](http://github.com/benhutton).

* Deprecated the `default_cassette_record_mode` option.  Use `default_cassette_options[:record_mode]` instead.

## 0.1.2 March 4, 2010

[Full Changelog](http://github.com/myronmarston/vcr/compare/v0.1.1...v0.1.2)

* Added explanatory note about VCR to `FakeWeb::NetConnectNotAllowedError#message`.

* Got things to work for when a cassette records multiple requests made to the same URL with the same HTTP verb,
  but different responses. We have to register an array of responses with fakeweb.

* Fixed our `Net::HTTP` monkey patch so that it only stores the recorded response once per request.
  Internally, `Net::HTTP#request` recursively calls itself (passing slightly different arguments) in certain circumstances.

## 0.1.1 February 25, 2010

[Full Changelog](http://github.com/myronmarston/vcr/compare/v0.1.0...v0.1.1)

* Handle asynchronous HTTP requests (such as for mechanize).  Bug reported by [Thibaud Guillaume-Gentil](http://github.com/thibaudgg).

## 0.1.0 February 25, 2010

[Full Changelog](http://github.com/myronmarston/vcr/compare/d2577f79247d7db60bf160881b1b64e9fa10e4fd...v0.1.0)

* Initial release.  Basic recording and replaying of responses works.
