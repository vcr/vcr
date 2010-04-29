#Changelog

## 0.4.0 April 28, 2010
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
* Fixed a bug: when `Net::HTTP#request` was called with a block that had a return statement, the response was not being recorded.

## 0.3.0 March 24, 2010
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
* Added `:allow_real_http` cassette option, which allows VCR to work with capybara and a javascript driver.
  Bug reported by [Ben Hutton](http://github.com/benhutton).

* Deprecated the `default_cassette_record_mode` option.  Use `default_cassette_options[:record_mode]` instead.

## 0.1.2 March 4, 2010
* Added explanatory note about VCR to `FakeWeb::NetConnectNotAllowedError#message`.

* Got things to work for when a cassette records multiple requests made to the same URL with the same HTTP verb,
  but different responses. We have to register an array of responses with fakeweb.

* Fixed our `Net::HTTP` monkey patch so that it only stores the recorded response once per request.
  Internally, `Net::HTTP#request` recursively calls itself (passing slightly different arguments) in certain circumstances.

## 0.1.1 February 25, 2010
* Handle asynchronous HTTP requests (such as for mechanize).  Bug reported by [Thibaud Guillaume-Gentil](http://github.com/thibaudgg).

## 0.1.0 February 25, 2010
* Initial release.  Basic recording and replaying of responses works.