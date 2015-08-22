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
  spec.add_development_dependency "yard"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "fakeweb"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "cucumber"
  spec.add_development_dependency "aruba"
  spec.add_development_dependency "faraday", "0.9.0"
  spec.add_development_dependency "httpclient"
  spec.add_development_dependency "excon"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "multi_json"
  spec.add_development_dependency "json"
  spec.add_development_dependency "typhoeus"
  spec.add_development_dependency "patron"
  spec.add_development_dependency "em-http-request"
  spec.add_development_dependency "curb"
  spec.add_development_dependency "yajl-ruby"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "relish"
  spec.add_development_dependency "mime-types"
  spec.add_development_dependency "sinatra"
end
