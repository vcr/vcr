#!/usr/bin/env bash

# start up a JRuby nailgun server (and ensure it shuts down on exit)
ruby --ng-server > /dev/null 2>&1 &
trap "script/shutdown_jruby_nailgun.rb" EXIT

bundle exec cucumber
# bundle install
# bundle exec rake cucumber
# bundle exec cucumber --profile wip

