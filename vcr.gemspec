lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'vcr/version'
require 'bundler'

Gem::Specification.new do |s|
  s.name = "vcr"
  s.homepage = "http://github.com/myronmarston/vcr"
  s.authors = ["Myron Marston"]
  s.summary = "Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests."
  s.description = "VCR provides helpers to record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.  It works with any ruby testing framework, and provides built-in support for cucumber."
  s.email = "myron.marston@gmail.com"
  s.files = Dir.glob("lib/**/*") + %w[LICENSE README.md CHANGELOG.md]
  s.require_paths = ["lib"]

  s.version = VCR.version
  s.required_ruby_version = '>= 1.8.6'
  s.required_rubygems_version = '>= 1.3.5'
  s.add_bundler_dependencies
end
