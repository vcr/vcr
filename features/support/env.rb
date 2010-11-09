require 'rubygems'
require 'bundler'
Bundler.setup

# Current version of aruba won't run on JRuby or Rubinius due to
# dependency on background_process.  We have a work around to fix this.
NEEDS_ARUBA_FIX = defined?(RUBY_ENGINE) && %w[ jruby rbx ].include?(RUBY_ENGINE)

$LOAD_PATH.unshift File.dirname(__FILE__) + '/aruba_workaround' if NEEDS_ARUBA_FIX

require 'aruba'
require 'aruba_patches' if NEEDS_ARUBA_FIX

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
end
