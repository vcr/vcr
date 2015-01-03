#!/usr/bin/env ruby
# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vcr/version"

Gem::Specification.new do |spec|
  spec.name          = "vcr"
  spec.version       = VCR.version
  spec.authors       = ["Myron Marston"]
  spec.email         = ["myron.marston@gmail.com"]
  spec.summary       = %q{Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.}
  spec.description   = spec.summary
  spec.homepage      = "http://vcr.github.io/vcr"
  spec.license       = "MIT"

  spec.files         = Dir[File.join("lib", "**", "*")]
  spec.executables   = Dir[File.join("bin", "**", "*")].map! { |f| f.gsub(/bin\//, "") }
  spec.test_files    = Dir[File.join("test", "**", "*"), File.join("spec", "**", "*"), File.join("features", "**", "*")]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "pry-doc", "~> 0.6"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.4"
  spec.add_development_dependency "yard", "~> 0.4"
  spec.add_development_dependency "rack", ">= 1.3.6"
  spec.add_development_dependency "fakeweb", ">= 1.3.0"
  spec.add_development_dependency "webmock", ">= 1.14"
  spec.add_development_dependency "cucumber", ">= 1.1.4"
  spec.add_development_dependency "aruba", ">= 0.5"
  spec.add_development_dependency "faraday", ">= 0.8"
  spec.add_development_dependency "httpclient", ">= 2.2"
  spec.add_development_dependency "excon", ">= 0.22"
  spec.add_development_dependency "timecop", "0.6.1"
  spec.add_development_dependency "multi_json", ">= 1.0.3"
  spec.add_development_dependency "json", ">= 1.6.5"
  spec.add_development_dependency "redis", ">= 2.2.2"
  spec.add_development_dependency "typhoeus", ">= 0.6"
  spec.add_development_dependency "patron", ">= 0.4.15"
  spec.add_development_dependency "em-http-request", ">= 1.0.2"
  spec.add_development_dependency "curb", ">= 0.8.0"
  spec.add_development_dependency "yajl-ruby", ">= 1.1.0"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "relish", "~> 0.6"
  spec.add_development_dependency "mime-types", "< 2.0"
  spec.add_development_dependency "redcarpet"
end
