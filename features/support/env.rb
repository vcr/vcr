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
  rubyopt = "--disable-gems #{rubyopt}" unless "rbx" == ruby_engine
end

Before do
  if "jruby" == ruby_engine
    aruba.config.io_wait_timeout = 0.1
  else
    aruba.config.io_wait_timeout = 0.02
  end
end

Before("~@with-bundler") do
  set_environment_variable("RUBYLIB", load_paths.join(":"))
  set_environment_variable("RUBYOPT", rubyopt)
  set_environment_variable("RBXOPT", "--disable-gems #{ENV["RBXOPT"]}") if "rbx" == ruby_engine
  set_environment_variable("GEM_HOME", nil)
end

Before("@with-bundler") do
  set_environment_variable("RUBYLIB", ".:#{ENV["RUBYLIB"]}:#{load_paths.last}")
  set_environment_variable("RUBYOPT", "#{ENV["RUBYOPT"]} -rsupport/cucumber_helpers")
  set_environment_variable("BUNDLE_GEMFILE", Bundler.default_gemfile.expand_path.to_s)
end
