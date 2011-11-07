See the [Changelog](changelog) for a complete list of changes from VCR
1.x to 2.0. This file simply lists the most pertinent ones to upgrading.

## Configuration Changes

In VCR 1.x, your configuration block would be something like this:

``` ruby
VCR.config do |c|
  c.cassette_library_dir = 'cassettes'
  c.stub_with :fakeweb, :typhoeus
end
```

This will continue to work in VCR 2.0 but will generate deprecation
warnings. Instead, you should change this to:

``` ruby
VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :fakeweb, :typhoeus
end
```

## New Cassette Format

The cassette format has changed between VCR 1.x and VCR 2.0.
VCR 1.x cassettes cannot be used with VCR 2.0.

The easiest way to upgrade is to simply delete your cassettes and
re-record all of them. VCR also provides a rake task that attempts
to upgrade your 1.x cassettes to the new 2.0 format. To use it, add
the following line to your Rakefile:

``` ruby
load 'vcr/tasks/vcr.rake'
```

Then run `rake vcr:migrate_cassettes DIR=path/to/your/cassettes/directory` to
upgrade your cassettes. Note that this rake task may be unable to
upgrade some cassettes that make extensive use of ERB. In addition, now
that VCR 2.0 does less normalization then before, it may not be able to
migrate the cassette perfectly. It's recommended that you delete and
re-record your cassettes if you are able.

