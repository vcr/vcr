require 'rubygems'
require 'bundler'
Bundler.setup

require 'ruby-debug' if !defined?(RUBY_ENGINE) && RUBY_VERSION != '1.9.3' && !ENV['CI']

require 'aruba/cucumber'
require 'aruba/jruby' if RUBY_PLATFORM == 'java'

additional_paths = []
Before('@rspec-1') do
  additional_paths << File.join(%w[ .. .. vendor rspec-1 bin ])
end

Before do
  load_paths, requires = ['../../lib'], []

  # Put any bundler-managed gems (such as :git gems) on the load path for when aruba shells out.
  # Alternatively, we could hook up aruba to use bundler when it shells out, but invoking bundler
  # for each and every time aruba starts ruby would slow everything down. We really only need it for
  # bundler-managed gems.
  load_paths.push($LOAD_PATH.grep %r|bundler/gems|)

  if RUBY_VERSION < '1.9'
    requires << "rubygems"
  else
    load_paths << '.'
  end

  requires << '../../features/support/vcr_cucumber_helpers'
  requires.map! { |r| "-r#{r}" }
  set_env('RUBYOPT', "-I#{load_paths.join(':')} #{requires.join(' ')}")

  if additional_paths.any?
    existing_paths = ENV['PATH'].split(':')
    set_env('PATH', (additional_paths + existing_paths).join(':'))
  end

  @aruba_timeout_seconds = 60
end

