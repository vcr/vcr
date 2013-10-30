# Kill the whole script on error
set -e -x

# idea taken from: http://blog.headius.com/2010/03/jruby-startup-time-tips.html
export JRUBY_OPTS='-X-C' # disable JIT since these processes are so short lived

# force jRuby to use client mode JVM or a compilation mode thats as close as possible,
# idea taken from https://github.com/jruby/jruby/wiki/Improving-startup-time
export JAVA_OPTS='-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1'

echo "-------- Running Typhoeus 0.4 Specs ---------"
bundle install --gemfile=gemfiles/typhoeus_old.gemfile --without extras
BUNDLE_GEMFILE=gemfiles/typhoeus_old.gemfile bundle exec rspec spec/vcr/library_hooks/typhoeus_0.4_spec.rb --format progress --backtrace

# Setup vendored rspec-1
bundle exec rake submodules

echo "-------- Running Specs ---------"
bundle exec ruby -I./spec -r./spec/capture_warnings -rspec_helper -S rspec spec --format progress --backtrace

echo "-------- Running Cukes ---------"
bundle exec cucumber

echo "-------- Checking Coverage ---------"
bundle exec rake yard_coverage

bundle exec rake check_code_coverage
