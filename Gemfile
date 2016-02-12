source 'https://rubygems.org'

gem "faraday", ">= 0.9.2"

gemspec

gem 'jruby-openssl', :platforms => :jruby

platform :mri do
  gem "typhoeus"
  gem "patron"
  gem "em-http-request"
  gem "curb", "~> 0.8.8"
end

platform :ruby do
  gem "yajl-ruby"
end
