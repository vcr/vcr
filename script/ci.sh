# Kill the whole script on error
set -e -x

# Setup vendored rspec-1
git submodule init
git submodule update

echo "-------- Running Specs ---------"
bundle exec ruby -w -I./spec -r./spec/capture_warnings -rspec_helper -S rspec spec --format progress --backtrace

echo "-------- Running Cukes ---------"
bundle exec cucumber

echo "-------- Checking Coverage ---------"
bundle exec rake yard_coverage

bundle exec rake check_code_coverage
