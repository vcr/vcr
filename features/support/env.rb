require 'rubygems'
require 'bundler'
Bundler.setup

require 'ruby-debug' if !defined?(RUBY_ENGINE) && RUBY_VERSION != '1.9.3' && !ENV['CI']

require 'aruba/cucumber'

cucumer_helpers_file = '../../features/support/vcr_cucumber_helpers'
if RUBY_VERSION > '1.9.1'
  Before do
    set_env('RUBYOPT', "-I.:../../lib -r#{cucumer_helpers_file}")
  end
elsif RUBY_PLATFORM == 'java'
  Before do
    set_env('RUBYOPT', "-I../../lib -rubygems -r#{cucumer_helpers_file}")

    # ideas taken from: http://blog.headius.com/2010/03/jruby-startup-time-tips.html
    set_env('JRUBY_OPTS', '-X-C') # disable JIT since these processes are so short lived
    set_env('JAVA_OPTS', '-d32') # force jRuby to use client JVM for faster startup times
  end
else
  Before do
    set_env('RUBYOPT', "-rubygems -r#{cucumer_helpers_file}")
  end
end

Before do
  @aruba_timeout_seconds = RUBY_PLATFORM == 'java' ? 60 : 20
end

