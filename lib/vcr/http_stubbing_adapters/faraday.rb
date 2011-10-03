require 'vcr/util/version_checker'
require 'faraday'

VCR::VersionChecker.new('Faraday', Faraday::VERSION, '0.6.0', '0.6').check_version!

=begin

TODO: Figure out what to do with the Faraday adapter.  Some thoughts:

  1. The middleware is all that's needed to hook into FakeWeb. This file can be removed.
  2. The middleware is very weird and different from the normal way you use VCR (i.e. the
     cassette wraps multiple requests but for the middleware, it wraps only one). Maybe
     the middleware should be changed to conform?
  3. We use to support users configuring `stub_with :faraday`...should we still support that?
     Or make it a no-op with a warning?
  4. The Faraday middleware is a bit out of date with Faraday anyway...so it'd be good
     to make it current as part of this process.

=end
