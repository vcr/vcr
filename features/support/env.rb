require 'bundler'
Bundler.setup

ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"

require 'aruba/cucumber'
require 'aruba/jruby' if RUBY_PLATFORM == 'java'

gem_specs = Bundler.load.specs
load_paths = Dir.glob(gem_specs.map { |spec|
  if spec.respond_to?(:lib_dirs_glob)
    spec.lib_dirs_glob
  else
    spec.load_paths
  end
}.flatten)

load_paths << File.expand_path("../../../spec", __FILE__)
rubyopt = "-rsupport/cucumber_helpers"

if RUBY_VERSION > '1.9'
  load_paths.unshift(".")
  rubyopt = "--disable-gems #{rubyopt}" if "ruby" == ruby_engine
end

Before do
  @aruba_timeout_seconds = 30
  if "jruby" == ruby_engine
    @aruba_io_wait_seconds = 0.1
  else
    @aruba_io_wait_seconds = 0.02
  end
end

Before("~@with-bundler") do
  set_env("RUBYLIB", load_paths.join(":"))
  set_env("RUBYOPT", rubyopt)
end

Before("@with-bundler") do
  set_env("RUBYLIB", ".:#{ENV["RUBYLIB"]}:#{load_paths.last}")
  set_env("RUBYOPT", "#{ENV["RUBYOPT"]} -rsupport/cucumber_helpers")
  set_env("BUNDLE_GEMFILE", Bundler.default_gemfile.expand_path.to_s)
end
