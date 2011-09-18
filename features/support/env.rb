require 'rubygems'
require 'bundler'
Bundler.setup

require 'aruba/cucumber'

Before do
  this_dir = File.dirname(__FILE__)
  in_current_dir do
    FileUtils.ln_s File.join(this_dir, 'vcr_cucumber_helpers.rb'), 'vcr_cucumber_helpers.rb'
  end
end

if RUBY_VERSION > '1.9.1'
  Before do
    set_env('RUBYOPT', '-I.:../../lib')
  end
elsif RUBY_PLATFORM == 'java'
  Before do
    set_env('RUBYOPT', '-I../../lib -rubygems')

    # ideas taken from: http://blog.headius.com/2010/03/jruby-startup-time-tips.html
    set_env('JRUBY_OPTS', '-X-C') # disable JIT since these processes are so short lived
    set_env('JAVA_OPTS', '-d32') # force jRuby to use client JVM for faster startup times
  end
end

Before do
  @aruba_timeout_seconds = RUBY_PLATFORM == 'java' ? 60 : 10
end

