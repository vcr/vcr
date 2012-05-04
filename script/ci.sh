# Kill the whole script on error
set -e

# Setup vendored rspec-1
git submodule init
git submodule update

bundle exec ruby -w -I./spec -r./spec/capture_warnings -rspec_helper -S rspec spec --format progress --backtrace

bundle exec cucumber

bundle exec rake yard_coverage

bundle exec rake check_code_coverage
