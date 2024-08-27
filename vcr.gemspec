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
  spec.homepage      = "https://benoittgt.github.io/vcr"
  spec.licenses       = ["Hippocratic-2.1", "MIT"]

  spec.files         = Dir[File.join("lib", "**", "*")]
  spec.executables   = Dir[File.join("bin", "**", "*")].map! { |f| f.gsub(/bin\//, "") }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "base64"

  spec.metadata["changelog_uri"] = "https://github.com/vcr/vcr/blob/master/CHANGELOG.md"
end
