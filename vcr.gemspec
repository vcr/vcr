require File.expand_path("../lib/vcr/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "vcr"
  s.homepage = "http://github.com/myronmarston/vcr"
  s.authors = ["Myron Marston"]
  s.summary = "Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests."
  s.description = "VCR provides helpers to record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.  It works with any ruby testing framework, and provides built-in support for cucumber."
  s.email = "myron.marston@gmail.com"
  s.require_path = "lib"
  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact

  s.version = VCR.version
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.6'
  s.required_rubygems_version = '>= 1.3.5'

  {
    'bundler'         => '~> 1.0.0',
    'rake'            => '~> 0.8.7',

    'rspec'           => '~> 2.0.0.beta.20',
    'cucumber'        => '~> 0.8.5',

    'fakeweb'         => '~> 1.3.0',
    'webmock'         => '~> 1.3.5',

    'httpclient'      => '~> 2.1.5.2',

    'capybara'        => '~> 0.3.9',
    'rack'            => '1.2.0'
  }.each do |lib, version|
    s.add_development_dependency lib, version
  end

  {
    'patron'          => '~> 0.4.6',
    'em-http-request' => '~> 0.2.7',
  }.each do |lib, version|
    s.add_development_dependency lib, version
  end unless RUBY_PLATFORM == 'java'
end
