#!/bin/bash
set -e

STATUS=0
warnings="${TMPDIR:-/tmp}/vcr-warnings.$$"

nano_cmd="$(type -p gdate date | head -1)"
nano_format="+%s%N"
[ "$(uname -s)" != "Darwin" ] || nano_format="${nano_format/%N/000000000}"

travis_time_start() {
  travis_timer_id=$(printf %08x $(( RANDOM * RANDOM )))
  travis_start_time=$($nano_cmd -u "$nano_format")
  printf "travis_time:start:%s\r\e[0m" $travis_timer_id
}

travis_time_finish() {
  local travis_end_time=$($nano_cmd -u "$nano_format")
  local duration=$(($travis_end_time-$travis_start_time))
  printf "travis_time:end:%s:start=%s,finish=%s,duration=%s\r\e[0m" \
    $travis_timer_id $travis_start_time $travis_end_time $duration
}

fold() {
  local name="$1"
  local status=0
  shift 1
  if [ -n "$TRAVIS" ]; then
    printf "travis_fold:start:%s\r\e[0m" "$name"
    travis_time_start
  fi

  "$@" || status=$?

  [ -z "$TRAVIS" ] || travis_time_finish

  if [ "$status" -eq 0 ]; then
    if [ -n "$TRAVIS" ]; then
      printf "travis_fold:end:%s\r\e[0m" "$name"
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

check_warnings() {
  # Display Ruby warnings from this project's source files. Abort if any were found.
  num="$(grep -F "$PWD" "$warnings" | grep -v "${PWD}/vendor/bundle" | sort | uniq -c | sort -rn | tee /dev/stderr | wc -l)"
  rm -f "$warnings"
  if [ "$num" -gt 0 ]; then
    echo "FAILED: this test suite doesn't tolerate Ruby syntax warnings!" >&2
    exit 1
  fi
}

trap 'exit 1' INT

# idea taken from: http://blog.headius.com/2010/03/jruby-startup-time-tips.html
export JRUBY_OPTS='-X-C' # disable JIT since these processes are so short lived

# force jRuby to use client mode JVM or a compilation mode thats as close as possible,
# idea taken from https://github.com/jruby/jruby/wiki/Improving-startup-time
export JAVA_OPTS='-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1'

export SPEC_OPTS="--backtrace --profile"

BUNDLE_GEMFILE=gemfiles/typhoeus_old.gemfile fold "typhoeus-old" \
  run script/test spec/lib/vcr/library_hooks/typhoeus_0.4_spec.rb

BUNDLE_GEMFILE=gemfiles/faraday_old.gemfile fold "faraday-old" \
  run script/test spec/lib/vcr/middleware/faraday_spec.rb spec/lib/vcr/library_hooks/faraday_spec.rb \
    features/middleware/faraday.feature

fold "spec" run script/test spec/

fold "features" run script/test features/

check_warnings

fold "doc-coverage" bundle exec rake yard_coverage

bundle exec rake check_code_coverage

exit $STATUS
