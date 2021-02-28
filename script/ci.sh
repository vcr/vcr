#!/bin/bash
set -e

STATUS=0
warnings="${TMPDIR:-/tmp}/vcr-warnings.$$"

fold() {
  local name="$1"
  local status=0
  shift 1
  if [ -n "$CI" ]; then
    echo "::group::${name}"
  fi

  "$@" || status=$?

  if [ "$status" -eq 0 ]; then
    if [ -n "$CI" ]; then
      echo "::endgroup::"
    fi
  else
    STATUS="$status"
  fi

  # We keep track of the status using `STATUS` and exit with
  # it below, so we don't return the status here.
}

run() {
  # Save warnings on stderr to a separate file
  RUBYOPT="$RUBYOPT -w" "$@" 2> >(tee >(grep 'warning:' >>"$warnings") | grep -v 'warning:')
}

fetch_warnings() {
  grep -F "$PWD" "$1" | \
    grep -v "${PWD}/vendor/bundle" | \
    grep -v "${PWD}/spec/.\+possible reference to past scope"
}

check_warnings() {
  # Display Ruby warnings from this project's source files. Abort if any were found.
  num="$(fetch_warnings "$warnings" | sort | uniq -c | sort -rn | tee /dev/stderr | wc -l)"
  rm -f "$warnings"
  if [ "$num" -gt 0 ]; then
    echo "FAILED: this test suite doesn't tolerate Ruby syntax warnings!" >&2
    exit 1
  fi
}

trap 'exit 1' INT

RUBY_ENGINE="$(ruby -e 'puts defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"')"

# idea taken from: http://blog.headius.com/2010/03/jruby-startup-time-tips.html
export JRUBY_OPTS='-X-C' # disable JIT since these processes are so short lived

# force jRuby to use client mode JVM or a compilation mode thats as close as possible,
# idea taken from https://github.com/jruby/jruby/wiki/Improving-startup-time
export JAVA_OPTS='-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1'

export SPEC_OPTS="--backtrace --profile"

if [ "$RUBY_ENGINE" = "ruby" ]; then
  BUNDLE_GEMFILE=Gemfile.typhoeus-0.4 fold "typhoeus-0.4" \
    run script/test spec/lib/vcr/library_hooks/typhoeus_0.4_spec.rb
fi

BUNDLE_GEMFILE=Gemfile.faraday-1.0.0 fold "faraday-1.0.0" \
  run script/test spec/lib/vcr/middleware/faraday_spec.rb spec/lib/vcr/library_hooks/faraday_spec.rb \
    features/middleware/faraday.feature

BUNDLE_GEMFILE=Gemfile.cucumber-3.1 fold "cucumber-3.1" \
  run script/test features/test_frameworks/cucumber.feature

fold "spec" run script/test spec/

fold "features" run script/test features/

check_warnings

if ! bundle exec yard stats --list-undoc | tee /dev/stdout | grep -q '100.00% documented'; then
  echo "Failed: documentation coverage is less than 100%"
  STATUS=1
fi

exit $STATUS
