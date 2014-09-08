## 2.9.3 (September 7, 2014)
[Full Changelog](http://github.com/vcr/vcr/compare/v2.9.2...v2.9.3)

Bug Fixes:

* Fix `VCR::Cassette#serializable_hash` so that it does not allow
  `before_record` hooks to apply mutations to existing HTTPInteraction
  instances. (Myron Marston)

## 2.9.2 (May 27, 2014)
[Full Changelog](http://github.com/vcr/vcr/compare/v2.9.1...v2.9.2)

Bug Fixes:

* Fix RSpec metadata integration once more -- we changed it a bit more
  in response to user feedback. (Myron Marston)

## 2.9.1 (May 23, 2014)
[Full Changelog](http://github.com/vcr/vcr/compare/v2.9.0...v2.9.1)

Bug Fixes:

* Fix RSpec metadata integration to not trigger deprecation warnings
  with RSpec 3.0.0.rc1+. (Janko Marohnić)

## 2.9.0 (March 27, 2014)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.8.0...v2.9.0)

Enhancements:

* Update version checking to only assert that a given library is >=
  a minimum version. (Ryan Foster)
* Explicitly support the latest Excon release (0.32). (Ryan Foster)
* Explicitly support the latest Excon release (0.31). (Michiel de Mare)
* Explicitly support the latest Webmock releases (1.16, 1.17).
  (Ryan Foster, Lawson Kurtz)

## 2.8.0 (November 23, 2013)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.7.0...v2.8.0)

Enhancements:

* Explicitly support the latest Excon release (0.29). (Myron Marston)
* Add `:body_as_json` request matcher. (Mike Dalton)
* Include the body in the `UnhandledHTTPRequestError` message when
  matching on `:body` to help identify the request. (Chris Gunther)

Bug Fixes:

* Fix Excon adapter so that it properly records responses even when
  a middleware raises an error (such as via the `:expects` Excon
  option). Previously, the order `response_call` was invoked on
  Excon middleware caused VCR's recording ot be skipped when an
  error was raised by another middleware. To fix this, we have
  split up VCR Excon middleware into two middlewares that we can
  insert into the stack at the appropriate spots. Note that to get
  this to work, Excon < 0.25.2 is no longer supported.
  (Myron Marston)
* Fix Excon adapter so that we pass it a dup of the body string
  rather than the body string itself, since Excon has code paths
  that will mutate the stubbed response string we give it, wreaking
  confusing havoc. (Myron Marston)
* Fix rspec metadata implementation so that it does not emit warnings
  on RSpec 2.99. (Herman Verschooten)

## 2.7.0 (October 31, 2013)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.6.0...v2.7.0)

Enhancements:

* Explicitly support the latest WebMock releases (1.14 and 1.15).
  (Eduardo Maia, Johannes Würbach)
* Explicitly support the latest Excon releases (0.27 and 0.28).
  (Myron Marston)
* Add support for Excon unix sockets by leveraging its
  new `::Excon::Utils.request_uri` method. (Todd Lunter)
* Reword the "it may not work with this version" warning
  message so the intent is more clear (Myron Marston).
* Support post/put bodies being specified as a hash when
  using Typhoeus by leveraging it's new `encoded_body` API.
  (Myron Marston, Hans Hasselberg)

Bug Fixes:

* Fix detection of encoding errors for MultiJson 1.8.1+.
  (Myron Marston).
* Fix file name sanitization to better handle paths that have
  a dot in them (Rob Hanlon, Myron Marston).
* Fix Faraday middleware so that it works properly when another
  adapter is exclusively enabled (Myron Marston).

## 2.6.0 (September 25, 2013)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.5.0...v2.6.0)

Enhancements:

* Add `VCR::Cassette#originally_recorded_at` for use when freezing
  time based on when the cassette was recorded. (Myron Marston)
* Improve the `:allow_unused_http_interactions => false` option
  so that it does not raise an error when there are unused interactions
  due to the test failing on its own; otherwise, it could raise
  an error and silence the original test failure. (Myron Marston)
* Improve perf when no logger is used by having it short-circuit
  and not bother formatting a logger message that won't be
  printed, anyway (Luan Santos and Matt Parker).

Bug Fixes:

* Fix confusing errors that could result when using the YAML serializer
  if the client code added some state (e.g. via an extension module)
  onto a request or response body. (Myron Marston)
* Ensure response body is always recorded when hooking into `:excon`,
  even when using a `:response_block` and an unexpected status is
  returned. Excon doesn't invoke the `:response_block` in this case,
  requiring special handling. (James Bence)
* Explicitly support the latest WebMock (1.13). (Ron Smith)
* Explicitly support the latest Excon (0.26). (Myron Marston)
* Fix detection of encoding errors to handle `ArgumentError` that
  is raised by recent versions of `MultiJson`. (Myron Marston)
* Fix Excon adapter so that it allows VCR to play nicely with
  manual Excon stubs (using Excon's `Excon.stub` API). (Myron Marston)
* Fix Typhoeus adapter so that it sets `effective_url` properly
  when the `:followlocation` option is used and a redirect is
  followed. (Myron Marston)

## 2.5.0 (May 18, 2013)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.4.0...v2.5.0)

Bug Fixes:

* Fix `around_http_request` so that it does not raise confusing
  errors when requests are made in multiple threads.
* Fix `configure_rspec_metadata!` so that you can safely call it
  more than once

Enhancements:

* Relax WebMock version checker to allow WebMock 1.10 and 1.11 without
  issuing warnings (Johannes Würbach and Myron Marston).
* Update Excon integration to take advantage of new Excon middleware
  architecture. This is a more robust way to hook into Excon and will
  be less prone to breakage due to internal Excon changes (Myron
  Marston).

Deprecations:

* Deprecate support for Typhoeus < 0.5. It will be removed in
  VCR 3.0 (Sheel Choksi).

## 2.4.0 (January 4, 2013)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.3.0...v2.4.0)

Enhancements:

* Add `:query` request matcher. The new `query_parser` config option can
  bet set to change how the query is parsed. Thanks to [Nathaniel
  Bibler](https://github.com/nbibler) for implementing this.

Bug Fixes:

* Fix previously recorded requests not matching when using the URIWithoutParams
  builtin matcher. In the case where the original request was recorded without
  parameters and subsequent requests filter out all parameters, the subsequent
  requests were failing to match the originally recorded request. Thanks to
  [Dmitry Jemerov](https://github.com/yole) for reporting the issue and
  [Nathaniel Bibler](https://github.com/nbibler) for implementing the fix.
* Set `effective_url` on Typhoeus response when playing back. Thanks to
  [Shay Frendt](https://github.com/shayfrendt) and
  [Ryan Castillo](https://github.com/rmcastil) for providing the fix and
  corresponding test.

Deprecations:

* Deprecate the `use_vcr_cassette` macro for RSpec. It has confusing
  semantics (e.g. calling it multiple times in the same example group
  can cause problems and it uses the same cassette for all examples
  in a group even though they may make different HTTP requests) and
  VCR's integration with RSpec metadata works much better. Thanks to
  [Austen Ito](https://github.com/austenito) for implementing this.
* Deprecate integration with FakeWeb. FakeWeb appears to be no longer
  maintained (0 commits in 2012 and it has pull requests that are
  2 years old) and WebMock is a far better option. Thanks to [Steve
  Faulkner](https://github.com/southpolesteve) for implementing this.

## 2.3.0 (October 29, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.2.5...v2.3.0)

Enhancements:

* Add `uri_parser` configuration option. It defaults to `URI` but can
  be set to something like `Addressable::URI` to handle non-standard
  URIs that stdlib `URI` doesn't handle. Thanks to [Ryan
  Burrows](https://github.com/rhburrows) for contributing this feature.
* Add support for Typhoeus 0.5. Thanks to [Hans
  Hasselberg](https://github.com/i0rek) for making the needed changes.

Bug Fixes:

* Fix `:use_scenario_name` cucumber tag option so that it only uses the
  first line of the scenario name. Scenarios can include a long preamble
  that Cucumber includes as part of the scenario name. Thanks to
  [Pascal Van Hecke](https://github.com/pascalvanhecke) for providing
  this fix.

## 2.2.5 (September 7, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.2.4...v2.2.5)

Enhancements:

* Include note about `debug_logger` option in error message for
  unhandled HTTP requests. Thanks to [Jacob Green](https://github.com/Jacobkg)
  for implementing this.

Bug Fixes:

* Fix another edge case bug on the excon adapter that was causing it
  to mis-record in certain situations that used Excon's :expects option.
* Fix the `:use_scenario_name` cucumber tags option to work properly
  with scenario outlines. Thanks to [Joe
  Nelson](https://github.com/begriffs) and [Stephen
  Anderson](https://github.com/bendycode) for the initial bug fixes and
  [Jacob Green](https://github.com/Jacobkg) for some further improvements.

## 2.2.4 (July 19, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.2.3...v2.2.4)

Bug Fixes:

* Fix excon so real requests are made with a connection constructed with
  same args as the original connection.

## 2.2.3 (July 9, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.2.2...v2.2.3)

Bug Fixes:

* Fix FakeWeb library hook so that it properly handles the case where
  multiple requests are made using the same Net::HTTP request object.
  Previously, a `NoMethodError` was raised. Thanks to [Jacob
  Green](https://github.com/Jacobkg) for helping to troubleshoot
  this bug!

## 2.2.2 (June 15, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.2.1...v2.2.2)

Bug Fixes:

* Fix `VCR.eject_cassette` so that it always pops a cassette off the
  cassette stack even if an error occurs while ejecting the cassette.
  This is important to keep things consistent, so that a cassette for
  one test doesn't remain in place for another test.

## 2.2.1 (June 13, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.2.0...v2.2.1)

Bug Fixes:

* Fix matcher generated by `VCR.request_matchers.uri_without_params` so that
  it handles URIs w/o query params properly. Previously, it would allow any
  two URIs w/o query params to match, even if the hosts or paths
  differed.

## 2.2.0 (May 31, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.1.1...v2.2.0)

Enhancements:

* Add new `:persist_with` cassette option. It allows you to provide a
  customized persistence implementation so you can persist it to
  something other than disk (i.e. a key-value store or a database).
  Thanks to [Chris Le](https://github.com/chrisle) for the idea and
  help with the implementation.
* Allow requests to be stubbed by external libraries (e.g. WebMock,
  FakeWeb or Typhoeus) without needing to turn VCR off.
* Add new `:allow_unused_http_interactions` cassette option. When set
  to false, an error will be raised when a cassette is ejected and
  there are remaining unused HTTP interactions. Thanks to
  [Mattias Putman](https://github.com/challengee) for the idea
  and initial implementation.

Bug Fixes:

* Fix `after_http_request` to handle symbol request predicate filters
  (e.g. `:ignored?`, `:stubbed?`, `:recordable?`, `:unhandled?`, `:real?`)
  properly. Previously using one of these would raise an ArgumentError.
  Thanks to [playupchris](https://github.com/playupchris) for reporting
  the bug and providing a fix.
* Fix FakeWeb hook so that it no longer breaks
  `FakeWeb.allow_net_connect?` with arguments. Thanks to
  [Ingemar](https://github.com/ingemar) for reporting the bug and
  providing a fix.
* Fix WebMock hook so that it no longer breaks
  `WebMock.net_connect_allowed?` with arguments. Thanks to
  [Gordon Wilson](https://github.com/gordoncww) for reporting the bug and
  providing a fix.
* Print a warning when VCR is used with a poorly behaved Faraday
  connection stack that has a middleware after the HTTP adapter.
  VCR may work improperly in this case.
* Raise an error if a response object is recorded with a non-string
  body. This fails early and indicates the problem rather than failing
  later with a strange error.
* Fix `filter_sensitive_data`/`define_cassette_placeholder` so that they
  handle non-strings gracefully (e.g. the port number as a Fixnum).
* Gracefully handle Faraday connection stacks that do not explicitly
  specify an HTTP adapter. Thanks to [Patrick Roby](https://github.com/proby)
  for reporting the bug.
* Work around a bug in WebMock's em-http-request adapter that prevented
  VCR from working when using the `:redirects` option with
  em-http-request. This change is just a work around. It fixes the main
  problem, but some features (such as the http request hooks) may not
  work properly for this case. The bug will ultimately need to be
  [fixed in WebMock](https://github.com/bblimke/webmock/pull/185).
  Thanks to [Mark Abramov](https://github.com/markiz) for reporting
  the bug and providing a great example test case.
* Fix bug in handling of Faraday requests with multipart uploads.
  Thanks to [Tyler Hunt](https://github.com/tylerhunt) for reporting
  and fixing the bug.

## 2.1.1 (April 24, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.1.0...v2.1.1)

* Fix `:use_scenario_name` cucumber tag option so that it works properly
  with multiple scenarios. Thanks to [Brent Snook](https://github.com/brentsnook)
  for reporting this bug.
* Fix `:use_scenario_name` cucumber tag option so that it only uses the
  first line of the scenario feature name. Cucumber includes all of the
  pre-amble text in the feature name but that can create a ridiculously
  long cassette name. Thanks to [Brent Snook](https://github.com/brentsnook)
  for reporting this bug.

## 2.1.0 (April 19, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.0.1...v.2.1.0)

* Add new `:use_scenario_name` option to the cucumber tags API. This
  allows you to use a generic tag (such as `@vcr`) and have the
  cassettes named based on the feature and scenario rather than based on
  the tag. Thanks to [Omer Rauchwerger](https://github.com/rauchy) for
  the implementation and [Chad Jolly](https://github.com/cjolly) for the
  initial idea and feedback.
* Add new `:decode_compressed_response` cassette option. When set to
  true, VCR will decompress a gzipped or deflated response before
  recording the cassette, in order to make it more human readable.
  Thanks to [Mislav Marohnić](https://github.com/mislav) for the
  idea and implementation.

## 2.0.1 (March 30, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.0.0...v2.0.1)

* Fix encoding logic to not attempt to encode the request or response
  body on deserialization if there is no encoding specified. This should
  allow cassettes recorded on 1.8 to work on 1.9. Thanks to
  [Kevin Menard](https://github.com/nirvdrum) for reporting the bug.
* Fix Excon adapter to fix a bug with Excon 0.11 and greater. When you
  passed a block to an excon request, the response body would not be
  recorded.
* Fix Faraday middleware so that it plays back parallel requests
  properly. Thanks to [Dave Weiser](https://github.com/davidann) for
  reporting this bug.

## 2.0.0 (March 2, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.0.0.rc2...v2.0.0)

* Add some additional logged events for the `debug_logger`.
* Don't worry about stripping the standard port from the request URI on
  playback. The standard port only needs to be stripped during recording;
  for playback, it will have already been stripped.  This allows people
  to use the `filter_sensitive_data` option in a way that changes the URI;
  before this change, doing so could result in `URI::InvalidURIError`.
  Thanks to [Patrick Schmitz](https://github.com/bullfight) and
  [Dan Thompson](https://github.com/danthompson) for reporting the issue
  and helping diagnose it.
* Relax Excon dependency to include newly released 0.10.
* Relax Faraday dependency to include 0.8.
* Fix Faraday library hook so that it always does the version checking.

## 2.0.0 RC 2 (February 23, 2012)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.0.0.rc1...v2.0.0.rc2)

## New Features

  * Add YARD documentation for the public API. Thanks to
    [Ben Oakes](https://github.com/benjaminoakes) for help with setting
    this up.
  * Fix `around_http_request` hook so that `request.proceed` returns
    the response.
  * Resolve `cassette_library_dir` to an absolute path. Thanks to
    [Nate Clark](https://github.com/heythisisnate) for the suggestion.
  * Add to the `VCR::Request` API in `before_http_request` and
    `after_http_request` hooks so the request has query methods like
    `#real?`, `#recordable?`, `#ignored?`, etc. Thanks to
    [Nate Clark](https://github.com/heythisisnate) for the idea.
  * Allow filters (objects that respond to `#to_proc`) to be passed
    to `before_http_request` and `after_http_request`.  This allows
    an API like `before_http_request(:real?)` or
    `after_http_request(lambda { |req| req.uri =~ /amazon/ })`.
  * Add `debug_logger` config option. This can be used to
    troubleshoot what VCR is doing.
  * Update WebMock to version (1.8.0) that supports Excon stubbing.
  * Store the encoding with the request & response bodies in the
    serialized cassette.
  * Add new `preserve_exact_body_bytes` option that base64 encodes the
    request or response body in order to preserve the bytes exactly.
    Thanks to [Jeff Pollard](https://github.com/Fluxx) for help
    designing this feature and for code reviewing it.
  * Update to and require latest Excon (0.9.6).

## Bug Fixes

  * Fix rspec metadata integration to allow the cassette name to be set
    at the example group level and apply to multiple examples. Thanks to
    [Paul Russell](https://github.com/pauljamesrussell) for reporting the
    bug.
  * Add missing `require 'vcr/version'` to the cassette migrator task.
    If you tried the migration rake task with 2.0.0.rc1 and got a
    `NoMethodError`, it should be fixed now.
  * Update Excon dependency to 0.9.5; 0.9.5 includes an important bug
    fix needed by VCR.
  * Ensure the excon retry limit is honored properly.
  * Ensure that the correct error class is raised by excon when stubbing
    an unexpected status.
  * Fix FakeWeb library hook so that it records the request body when
    using `Net::HTTP.post_form`. Thanks to
    [Retistic](https://github.com/Retistic) for reporting the bug.

## 2.0.0 RC 1 (December 8, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.0.0.beta2...v2.0.0.rc1)

* Add Faraday hook that automatically inserts the VCR middleware so that
  you can use VCR with Faraday without needing to insert the middleware
  yourself.  Use `VCR.configure { |c| c.hook_into :faraday }`.
* Add `ignore_request` config option. Pass it a block that returns
  true if the given request should be ignored.
* Improve the unhandled HTTP request error message so that it lists
  different options for how to get VCR to handle it.
* Add {before,after,around}_http_request hooks.
* Updated WebMock integration and bumped up required version to 1.7.8.
* Test against latest Excon (0.7.9) and confirm that VCR works fine with
  it.
* Add define_cassette_placeholder as an alias for filter_sensitive_data.
* Fix Faraday middleware so that it works properly when you use parallel
  requests.
* Integrate VCR with RSpec metadata. Thanks to [Ryan Bates](https://github.com/ryanb)
  for the great idea.

## 2.0.0 Beta 2 (November 6, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v2.0.0.beta1...v2.0.0.beta2)

* Update to (and require) Typhoeus 0.3.2.
* Fix a bug with `VCR.request_matchers.uri_without_param(:some_param)`
  so that it properly handles URIs that have no parameters. Thanks to
  [Sathya Sekaran](https://github.com/sfsekaran) for this fix.
* The cassette format has changed significantly:
  * The HTTPInteractions are no longer normalized in a lossy fashion.
    VCR 1.x converted all HTTP header keys to lowercase.  VCR 2.0 no
    longer does this because it is impossible to know what the original
    casing was (i.e. given `etag`, was it originally `etag`, `ETag` or
    `Etag`?). Also, some HTTP libraries add particular request headers
    to every request, and these used to be ignored. The aren't anymore.
  * The ruby struct objects are not directly serialized anymore.
    Instead, only primitives (hashes, arrays, strings, integers) are
    serialized. This allows swappable serializers and will allow other
    tools to read and use a VCR cassette.
  * Add new serializer API.  VCR ships with YAML, Syck, Psych and JSON
    serializers, and it is very simple to implement your own. The
    serializer can be configured on a per-cassette basis.
  * New `vcr:migrate_cassettes DIR=path/to/cassettes` rake task assists
    with upgrading from VCR 1.x to 2.0.
  * Cassettes now contain a `recorded_with` attribute. This should
    allow the cassette structure to be updated more easily in the future
    as the version number provides a means for easily migrating
    cassettes.
  * Add `recorded_at` to data serialized with an HTTPInteraction.  This
    allows the `:re_record_interval` cassette option to work more
    accurately and no longer rely on the file modification time.

Note that VCR 1.x cassettes cannot be used with VCR 2.0.  See the
upgrade notes for more info.

## 2.0.0 Beta 1 (October 8, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.11.3...v2.0.0.beta1)

### Changed

* Previously, the last matching response in a cassette would
  repeatedly playback if the same request kept being made. This is
  no longer the case.
* The Faraday middleware has been rewritten.
  * You no longer need to configure `stub_with :faraday` to use it.
  * It has been updated to work in parallel mode.
  * It no longer accepts a block and uses that to determine the
    cassette.  Instead, use `VCR.use_cassette` just like you would
    with FakeWeb or WebMock.

### Added

* Allow any callable (an object that responds to #call, such as a
  lambda) to be used as a request matcher. Thanks to [Avdi Grimm](https://github.com/avdi)
  for the idea.
* Add ability to register custom request matchers.
* Add `VCR.request_matchers.uri_without_param(:some_param)` to generate
  a request matcher that matches on URI but ignores the named parameter.
* New `:allow_playback_repeats` cassette option preserves the old
  playback repeat behavior. Thanks to [Avdi Grimm](https://github.com/avdi)
  for the idea.
* New `:exclusive` cassette option allows a cassette to be exclusively
  used rather than keeping the existing one active as a fallback. Thanks
  to [Avdi Grimm](https://github.com/avdi) for the idea.

### Removed

* Removed support for Ruby 1.8.6 and 1.9.1.
* Removed lots of old deprecated APIs.
* Removed support for manually changing the URI in a cassette to a regex.

### Deprecated

* Deprecated `VCR.config` in favor of `VCR.configure`.
* Deprecated `VCR::Config` singleton module in favor of
  `VCR::Configuration` class.  The current configuration instance
  can be accessed via `VCR.configuration`.
* Deprecated `stub_with` in favor of `hook_into`.  The stubbing
  adapters have been completely rewritten and are no longer an
  implementation of the adapter design pattern. Instead they simply
  use the named library to globally hook into every HTTP request.

## 1.11.3 (August 31, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.11.2...v1.11.3)

* Fix cassette serialization so that it does not include extra `ignored`
  instance variable.

## 1.11.2 (August 28, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.11.1...v1.11.2)

* Updated rake, cucumber and aruba dev dependencies to latest releases.
* Fix all warnings originating from VCR.  VCR is now warning-free!

## 1.11.1 (August 18, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.11.0...v1.11.1)

* Yanked 1.11.0 and rebuilt gem on 1.8.7 to deal with syck/psych
  incompatibilties in gemspec.

## 1.11.0 (August 18, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.10.3...v1.11.0)

* Updates to work with WebMock 1.7.0.

## 1.10.3 (July 21, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.10.2...v1.10.3)

* Fix `:update_content_length_header` option so no error is raised if
  a response body is nil. Bug reported by [jg](https://github.com/jg).

## 1.10.2 (July 16, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.10.1...v1.10.2)

* Yanked 1.10.1 and rebuilt gem on 1.8.7 to deal with syck/psych
  incompatibilties in gemspec.

## 1.10.1 (July 16, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.10.0...v1.10.1)

* Fix typo in error message.  Fix provided by [Bradley](https://github.com/bradleyisotope).
* Fix excon adapter to properly handle queries specified as a hash.
* Fix excon adapter to stub a response with a hash as excon expects.
  Fix provided by [Wesley Beary](https://github.com/geemus).
* Fix excon adapter so that it records a response even when excon raises
  an error due to an unexpected response.

## 1.10.0 (May 18, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.9.0...v1.10.0)

* Fix header normalization so that it properly handles nested arrays and
  non-string values.
* Add cucumber scenario documenting how VCR sanitizes cassette names
  to "normal" file names (i.e. only alphanumerics, no spaces).
* Add `:ignore_cassettes` option to `VCR.turn_off!`.  This causes
  cassette insertions to be ignored rather than to trigger an error.
  Patch provided by [Justin Smestad](https://github.com/jsmestad).
* Fix rack middleware to make it threadsafe.
* Update to latest RSpec (rspec 2.6).

## 1.9.0 (April 14, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.8.0...v1.9.0)

* Add support for [Excon](https://github.com/geemus/excon).

## 1.8.0 (March 31, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.7.2...v1.8.0)

* Updated Faraday middleware to work with newly released Faraday 0.6.0.

## 1.7.2 (March 26, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.7.1...v1.7.2)

* Fixed Typhoeus adapter so headers are returned in the same form during
  playback as they would be without VCR.  Bug reported by
  [Avdi Grimm](https://github.com/avdi).
* Fixed Faraday adapter so it treats response headers in the same way
  Faraday itself does (i.e. with lowercase keys).

## 1.7.1 (March 19, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.7.0...v1.7.1)

* Fix Faraday adapter so that it properly normalizes query parameters
  in the same way that Faraday itself does.

## 1.7.0 (March 1, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.6.0...v1.7.0)

* Use Psych for YAML serialization/deserialization when it is available.
  Syck, Ruby's old YAML engine, will remove whitespace from some
  strings.  Bug reported by [Robert Poor](https://github.com/rdpoor).
* Add new `:update_content_length_header` cassette option.  The option
  will ensure the `content-length` header value matches the actual
  response body length.
* Add new `:once` record mode.  It operates like `:new_episodes` except
  when the cassette file already exists, in which case it causes
  new requests to raise an error.  Feature suggested by
  [Jamie Cobbett](https://github.com/jamiecobbett).
* Made `:once` the default record mode.
* Add new `filter_sensitive_data` configuration option.  Feature
  suggested by [Nathaniel Bibler](https://github.com/nbibler).
* Commit to [Semantic Versioning](http://semver.org/).  The cucumber
  features document the public API for the purposes of semver.
* Add support for CI builds using [travis-ci](http://travis-ci.org/myronmarston/vcr).
* Add support for running tests through `gem test vcr`.  Visit
  [test.rubygems.org](http://test.rubygems.org/gems/vcr) to see
  the results.
* Fix cucumber support to use separate `Before` & `After` hooks rather than
  a single `Around` hook because of a bug in cucumber that prevents
  background steps from running within the `Around` hook.

## 1.6.0 (February 3, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.5.1...v1.6.0)

* Add new `ignore_hosts` configuration option that allows you to ignore
  any host (not just localhost aliases, as the `ignore_localhost` option
  works).  Feature suggested by [Claudio Poli](https://github.com/masterkain).
* Upgraded to the latest Typhoeus (0.2.1).
* General code clean up and refactoring.

## 1.5.1 (January 12, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.5.0...v1.5.1)

* Fix response and request serialization so that the headers are raw
  strings.  This fixes intermittent YAML seg faults for paperclip
  uploads to S3.  Bug reported by [Rob Slifka](https://github.com/rslifka).

## 1.5.0 (January 12, 2011)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.4.0...v1.5.0)

* Fix VCR::Cassette so it does not raise an error when a cassette file is
  empty.  Bug reported and fixed by [Karl Baum](https://github.com/kbaum).
* Lots of code cleanup.
* Fix the stubbing adapters so that they use the cassette instance
  rather than the cassette name to create and restore checkpoints.
* Raise an appropriate error when a nested cassette is inserted with the
  same name as a cassette that is already in the stack (VCR's design
  doesn't allow this and you would get weird errors later on).
* Raise an appropriate error when restoring a stubs checkpoint if the
  checkpoint cannot be found.
* Add `before_record` and `before_playback` hooks.  Idea and initial
  implementation by [Oliver Searle-Barnes](https://github.com/opsb);
  futher suggestions, testing and feedback by
  [Nathaniel Bibler](https://github.com/nbibler).

## 1.4.0 (December 3, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.3.3...v1.4.0)

* Added support for making HTTP requests without a cassette (i.e. if you don't
  want to use VCR for all of your test suite).  There are a few ways to
  enable this:
  * In your `VCR.config` block, set `allow_http_connections_when_no_cassette`
    to true to allow HTTP requests without a cassette.
  * You can temporarily turn off VCR using `VCR.turned_off { ... }`.
  * You can toggle VCR off and on with `VCR.turn_off!` and `VCR.turn_on!`.
* Fixed bug with `ignore_localhost` config option.  Previously, an error would
  be raised if it was set before the `stub_with` option.
* Added VCR::Middleware::Rack (see features/middleware/rack.feature for usage).
* Added support for Faraday (see features/middleware/faraday.feature for usage).

## 1.3.3 (November 21, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.3.2...v1.3.3)

* In specs, hit a local sinatra server rather than example.com.  This makes
  the specs faster and removes an external dependency.  The specs can pass
  without being online!
* Raise an explicit error when the http stubbing library is not configured
  (rather than letting the user get a confusing error later).
* Test against the latest WebMock release (1.6.1) (no changes required).
* Fix a few cucumber scenarios so they pass on rubinius and jruby.

## 1.3.2 (November 16, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.3.1...v1.3.2)

* Fix serialized structs so that they are normalized andthey will be the same
  regardless of which HTTP library made the request.
  * Status "OK " => "OK"
  * Body '' => nil
  * Headers {} => nil
  * Remove extraneous headers added by the HTTP lib (i.e. Typhoeus user agent)
* Rewrite cucumber features in a more documentation-oriented style.

## 1.3.1 (November 11, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.3.0...v1.3.1)

* Update WebMock adapter to work with (and require) newly released WebMock 1.6.0.

## 1.3.0 (November 11, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.2.0...v1.3.0)

* Moved documentation from README to [Wiki](http://github.com/vcr/vcr/wiki).
* Refactoring and code cleanup.
* Fix InternetConnection.available? so that it memoizes correctly when a connection is not available.
* Fix WebMock version checking to allow newly released 1.5.0 to be used without a warning.
* Add support for [Typhoeus](https://github.com/pauldix/typhoeus).  Thanks to
  [David Balatero](https://github.com/dbalatero) for making the necessary changes in Typhoeus
  to support VCR.
* Remove FakeWeb/WebMock inference logic.  You _must_ configure the http stubbing library
  explicitly now.

## 1.2.0 (October 13, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.1.2...v1.2.0)

* Improved the `:all` record mode so that it keeps previously recorded interactions that do not match the
  new recorded interactions.  Previously, all of the previously recorded interactions were deleted.
* Added `:re_record_interval` cassette option.  This option causes a cassette to be re-recorded when the
  existing file is older than the specified interval.
* Improved RSpec support.  Added #use_vcr_cassette RSpec macro method that sets up a cassette for an RSpec
  example group.
* Fixed VCR/Net::HTTP/WebMock integration so that VCR no longer loads its Net::HTTP monkey patch when
  WebMock is used, and relies upon WebMock's after_request callback to record Net::HTTP instead.  This
  fixes [a bug](http://github.com/vcr/vcr/issues/14) when using WebMock and Open URI.
* Consider 0.0.0.0 to be a localhost alias (previously only "localhost" and 127.0.0.1 were considered).
* Added spec and feature coverage for Curb integration.  Works out of the box with no changes required
  to VCR due to [Pete Higgins'](http://github.com/phiggins) great work to add Curb support to WebMock.
* Got specs and features to pass on rubinius.
* Changed WebMock version requirement to 1.4.0.

## 1.1.2 (September 9, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.1.1...v1.1.2)

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

[Full Changelog](http://github.com/vcr/vcr/compare/v1.1.0...v1.1.1)

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

[Full Changelog](http://github.com/vcr/vcr/compare/v1.0.3...v1.1.0)

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

[Full Changelog](http://github.com/vcr/vcr/compare/v1.0.2...v1.0.3)

* Upgraded VCR specs to RSpec 2.
* Updated `VCR::CucumberTags` so that it uses an `around` hook rather than a `before` hook and an `after` hook.
  Around hooks were added to Cucumber in the 0.7.3 release, so you'll have to be on that version or higher to use
  the `VCR::CucumberTags` feature.
* Updated the WebMock version requirement to 1.3.3 or greater.  1.3.2 and earlier versions did not properly handle
  multiple value for the same response header.
* Miscellaneous documentation updates.

## 1.0.2 (July 6, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.0.1...v1.0.2)

* Fixed VCR to work with [rest-client](http://github.com/archiloque/rest-client).  Rest-client extends the Net::HTTP
  response body string with a module containing additional data, which got serialized to the cassette file YAML
  and occasionally caused problems when the YAML was deserialized.  Bug reported by
  [Thibaud Guillaume-Gentil](http://github.com/thibaudgg).
* Setup bundler to manage development dependencies.

## 1.0.1 (July 1, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v1.0.0...v1.0.1)

* Fixed specs and features so they pass on MRI 1.9.2-preview3 and JRuby 1.5.1.
* Normalized response and request headers so that they are stored the same (i.e. lower case keys, arrays of values)
  in the cassette yaml files, regardless of which HTTP library is used.  This is the same way Net::HTTP normalizes
  HTTP headers.
* Fixed `VCR.use_cassette` so that it doesn't eject a cassette if an exception occurs while inserting one.
* Fixed FakeWeb adapter so that it works for requests that use basic auth. Patch submitted by
  [Eric Allam](http://github.com/rubymaverick).

## 1.0.0 (June 22, 2010)

[Full Changelog](http://github.com/vcr/vcr/compare/v0.4.1...v1.0.0)

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

[Full Changelog](http://github.com/vcr/vcr/compare/v0.4.0...v0.4.1)

* Fixed a bug: when `Net::HTTPResponse#read_body` was called after VCR had read the body to record a new request,
  it raised an error (`IOError: Net::HTTPResponse#read_body called twice`).  My fix extends Net::HTTPResponse
  so that it no longer raises this error.

## 0.4.0 April 28, 2010

[Full Changelog](http://github.com/vcr/vcr/compare/v0.3.1...v0.4.0)

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

[Full Changelog](http://github.com/vcr/vcr/compare/v0.3.0...v0.3.1)

* Fixed a bug: when `Net::HTTP#request` was called with a block that had a return statement, the response was not being recorded.

## 0.3.0 March 24, 2010

[Full Changelog](http://github.com/vcr/vcr/compare/v0.2.0...v0.3.0)

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

[Full Changelog](http://github.com/vcr/vcr/compare/v0.1.2...v0.2.0)

* Added `:allow_real_http` cassette option, which allows VCR to work with capybara and a javascript driver.
  Bug reported by [Ben Hutton](http://github.com/benhutton).

* Deprecated the `default_cassette_record_mode` option.  Use `default_cassette_options[:record_mode]` instead.

## 0.1.2 March 4, 2010

[Full Changelog](http://github.com/vcr/vcr/compare/v0.1.1...v0.1.2)

* Added explanatory note about VCR to `FakeWeb::NetConnectNotAllowedError#message`.

* Got things to work for when a cassette records multiple requests made to the same URL with the same HTTP verb,
  but different responses. We have to register an array of responses with fakeweb.

* Fixed our `Net::HTTP` monkey patch so that it only stores the recorded response once per request.
  Internally, `Net::HTTP#request` recursively calls itself (passing slightly different arguments) in certain circumstances.

## 0.1.1 February 25, 2010

[Full Changelog](http://github.com/vcr/vcr/compare/v0.1.0...v0.1.1)

* Handle asynchronous HTTP requests (such as for mechanize).  Bug reported by [Thibaud Guillaume-Gentil](http://github.com/thibaudgg).

## 0.1.0 February 25, 2010

[Full Changelog](http://github.com/vcr/vcr/compare/d2577f79247d7db60bf160881b1b64e9fa10e4fd...v0.1.0)

* Initial release.  Basic recording and replaying of responses works.
