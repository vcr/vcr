#!/bin/bash
set -e

STATUS=0
warnings="${TMPDIR:-/tmp}/vcr-warnings.$$"

run() {
  # Save warnings on stderr to a separate file
  RUBYOPT="$RUBYOPT -w" bundle exec "$@" \
    2> >(tee >(grep 'warning:' >>"$warnings") | grep -v 'warning:') || STATUS=$?
}

check_warnings() {
  # Display Ruby warnings from this project's source files. Abort if any were found.
  num="$(grep -F "$PWD" "$warnings" | grep -v "${PWD}/vendor/bundle" | sort | uniq -c | sort -rn | tee /dev/stderr | wc -l)"
  rm -f "$warnings"
  if [ "$num" -gt 0 ]; then
    echo "FAILED: this test suite doesn't tolerate Ruby syntax warnings!" >&2
    exit 1
  fi
}

# idea taken from: http://blog.headius.com/2010/03/jruby-startup-time-tips.html
export JRUBY_OPTS='-X-C' # disable JIT since these processes are so short lived

# force jRuby to use client mode JVM or a compilation mode thats as close as possible,
# idea taken from https://github.com/jruby/jruby/wiki/Improving-startup-time
export JAVA_OPTS='-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1'

export SPEC_OPTS="--backtrace"

echo "-------- Running Typhoeus 0.4 Specs ---------"
BUNDLE_GEMFILE=gemfiles/typhoeus_old.gemfile run rspec spec/vcr/library_hooks/typhoeus_0.4_spec.rb

echo "-------- Running Faraday 0.8 Specs ---------"
BUNDLE_GEMFILE=gemfiles/faraday_old.gemfile run rspec spec/vcr/middleware/faraday_spec.rb spec/vcr/library_hooks/faraday_spec.rb
BUNDLE_GEMFILE=gemfiles/faraday_old.gemfile run cucumber features/middleware/faraday.feature

echo "-------- Running Specs ---------"
run rspec

echo "-------- Running Cukes ---------"
run cucumber

echo "-------- Checking Coverage ---------"
bundle exec rake yard_coverage

bundle exec rake check_code_coverage

check_warnings

exit $STATUS
