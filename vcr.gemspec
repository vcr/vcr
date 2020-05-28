#!/usr/bin/env ruby
# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vcr/version"

Gem::Specification.new do |spec|
  spec.name          = "vcr"
  spec.version       = VCR.version
  spec.authors       = ["Myron Marston", "Kurtis Rainbolt-Greene", "Olle Jonsson"]
  spec.email         = ["kurtis@rainbolt-greene.online"]
  spec.summary       = %q{Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.}
  spec.description   = spec.summary
  spec.homepage      = "https://relishapp.com/vcr/vcr/docs"
  spec.licenses       = ["Hippocratic-2.1", "MIT"]

  spec.files         = Dir[File.join("lib", "**", "*")]
  spec.executables   = Dir[File.join("bin", "**", "*")].map! { |f| f.gsub(/bin\//, "") }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "test-unit", "~> 3.1.4"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "pry-doc", "~> 0.6"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.4"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "hashdiff", ">= 1.0.0.beta1", "< 2.0.0"
  spec.add_development_dependency "cucumber", "~> 3.1"
  spec.add_development_dependency "aruba", "~> 0.14.14"
  spec.add_development_dependency "faraday", ">= 0.11.0", "< 2.0.0"
  spec.add_development_dependency "httpclient"
  spec.add_development_dependency "excon", ">= 0.62.0"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "json"
  spec.add_development_dependency "relish"
  spec.add_development_dependency "mime-types"
  spec.add_development_dependency "sinatra"
end
