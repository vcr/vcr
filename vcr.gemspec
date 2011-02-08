$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "vcr/version"

Gem::Specification.new do |s|
  s.name = "vcr"
  s.homepage = "http://github.com/myronmarston/vcr"
  s.authors = ["Myron Marston"]
  s.summary = "Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests."
  s.description = "VCR provides helpers to record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.  It works with any ruby testing framework, and provides built-in support for cucumber."
  s.email = "myron.marston@gmail.com"
  s.require_path = "lib"
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {spec,features}/*`.split("\n")

  s.version = VCR.version
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.6'
  s.required_rubygems_version = '>= 1.3.5'

  {
    'bundler'         => '~> 1.0.7',
    'rake'            => '~> 0.8.7',

    'rspec'           => '~> 2.5',
    'cucumber'        => '~> 0.9.4',
    'aruba'           => '0.2.4',
    'shoulda'         => '~> 2.9.2',

    'fakeweb'         => '~> 1.3.0',
    'webmock'         => '~> 1.6.0',

    'faraday'         => '~> 0.5.3',
    'httpclient'      => '~> 2.1.5.2',

    'timecop'         => '~> 0.3.5',
    'rack'            => '1.1.0',
    'sinatra'         => '~> 1.1.0'
  }.each do |lib, version|
    s.add_development_dependency lib, version
  end

  {
    'patron'          => '~> 0.4.6',
    'em-http-request' => '~> 0.2.7',
    'curb'            => '~> 0.7.8',
    'typhoeus'        => '~> 0.2.1'
  }.each do |lib, version|
    s.add_development_dependency lib, version
  end unless RUBY_PLATFORM == 'java'
end
