# Development

This file details as many imporant parts of the process that you may need to know about working on VCR, should any of us get hit by a bus.

## Releasing

  0. Make a branch from the base branch
  0. Change the version in the gemspec, based on SEMVER
  0. Denote changes since last release in changelog file (see changelog notation below)
  0. Commit the changes with the body "Bumping to version X.Y.Z"
  0. Push the branch
  0. Make a pull request
  0. Get it merged
  0. Pull down the new master
  0. Run `bundle exec rake release`
  0. Grab a drink

Ancillary 1: We also have a thing called Relish, which I dislike immensley, but many people desire. It's on the last legs. You push the new relish documentation via `bundle exec rake relish`. I wish you the best of luck.

Ancillary 2: At your leasure make a Release on Github with the changelog differences. It's very helpful for many people.

## Changelog

We use a very rudementry changelog system focusing on three primary things people care about: Breaking Changes, New Features, and Bug fixes. Anything outside of that is worthless for people looking at the changelog in my experience. Here's a snippet for a new changelog entry:

``` markdown
## 5.1.0 (Feb 5, 2020)
[Full Changelog](https://github.com/vcr/vcr/compare/v5.0.0...v5.1.0)
  - Use RSpec metadata value as cassette name if value is String (#774)
  - Include body.class feedback for non-String body error (#756) …
  - Made our YAML output more inline with the spec to avoid issues (#782)
  - Fix broken build due to Hashdiff deprecation (#758)
  - [new] Use RSpec metadata value as cassette name if value is String (#774)
  - [new] Include body.class feedback for non-String body error (#756) …
  - [patch] Made our YAML output more inline with the spec to avoid issues (#782)
  - [patch] Fix broken build due to Hashdiff deprecation (#758)
  - Drop removed Travis directive (#751)
  - Repair Shields.io badges (#753)
  - Badges - swap out release for tag (#760)
  - Removing broken badges (#777)
  - Add record_on_error configuration option (#765)
  - [new] Add record_on_error configuration option (#765)
  - Clearing up intention of new maintainers request
  - Avoid updating the gem gem in system during travis build (#781)
  - Updated our version of Aruba (#780)
```

Notice a few things here:

  0. These log lines are basically from git log, thankfully including the PR. Sadly Github doesn't parse it, but whatever.
  0. The header is the version an the rough date. I actually dislike doing the date, because like does anyone actually care if you're looking at this file? Nah.
  0. The header has a link to the diff. Honestly, it should just be the release, but chicken-egg.
  0. We have 2 tags: [new], [patch], with the [breaking] not present in this release. Use those to help people focus on what they should care about. Sometimes the PR will already have that for you.
