$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "vcr/version"

Gem::Specification.new do |s|
  s.name = "vcr"
  s.homepage = "https://github.com/vcr/vcr"
  s.license = "MIT"
  s.authors = ["Myron Marston"]
  s.summary = "Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests."
  s.description = "VCR provides a simple API to record and replay your test suite's HTTP interactions.  It works with a variety of HTTP client libraries, HTTP stubbing libraries and testing frameworks."
  s.email = "myron.marston@gmail.com"
  s.require_path = "lib"
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {spec,features}/*`.split("\n")

  s.version = VCR.version
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.7'
  s.required_rubygems_version = '>= 1.3.5'

  s.add_development_dependency 'bundler', '>= 1.0.7'
  s.add_development_dependency 'rake', '~> 0.9.2'

  s.add_development_dependency 'cucumber', '~> 1.1.4'
  s.add_development_dependency 'aruba', '~> 0.4.11'

  s.add_development_dependency 'rspec', '~> 2.11'
  s.add_development_dependency 'shoulda', '~> 2.9.2'

  s.add_development_dependency 'fakeweb', '~> 1.3.0'
  s.add_development_dependency 'webmock', '~> 1.10'

  s.add_development_dependency 'faraday', '~> 0.8'
  s.add_development_dependency 'httpclient', '~> 2.2'
  s.add_development_dependency 'excon', '~> 0.22'

  s.add_development_dependency 'timecop', '~> 0.3.5'
  s.add_development_dependency 'rack', '~> 1.3.6'
  s.add_development_dependency 'sinatra', '~> 1.3.2'
  s.add_development_dependency 'multi_json', '~> 1.0.3'
  s.add_development_dependency 'json', '~> 1.6.5'
  s.add_development_dependency 'simplecov', '~> 0.5.3'
  s.add_development_dependency 'redis', '~> 2.2.2'
  s.add_development_dependency 'typhoeus', '~> 0.6'

  unless RUBY_PLATFORM == 'java'
    s.add_development_dependency 'patron', '~> 0.4.15'
    s.add_development_dependency 'em-http-request', '~> 1.0.2'
    s.add_development_dependency 'curb', '~> 0.8.0'
    s.add_development_dependency 'yajl-ruby', '~> 1.1.0'
  end
end
