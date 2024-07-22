source "https://rubygems.org"
gemspec

# TODO: Remove the pinned version of `ethon` once header issue affecting Typhoeus is resolved
# https://github.com/typhoeus/typhoeus/issues/705
gem "ethon", "0.15.0"

gem "aruba", "~> 0.14.14"
gem "bigdecimal"
gem "codeclimate-test-reporter", "~> 0.4"
gem "cucumber", "~> 9.0"
gem "curb", "~> 1.0.1"
gem "em-http-request"
gem "excon", ">= 0.62.0"

if ENV['FARADAY_VERSION'] == "1.0"
  gem "faraday", "~> 1.0"
else
  gem "faraday", "~> 2.0"
  gem "faraday-typhoeus"
  gem "faraday-patron", "~> 2.0"
  gem "faraday-multipart"
end

gem "hashdiff", ">= 1.0.0.beta1", "< 2.0.0"
gem "httpclient"
gem "json"
gem "mime-types"
gem "mutex_m"
gem "patron", "0.6.3"
gem "pry-doc", "~> 0.6"
gem "pry", "~> 0.9"

if ENV["RACK_VERSION"] == "2.0"
  gem "rack", "< 3"
else
  gem "rack", "~> 3.0"
  gem "rackup"
end

gem "rake", ">= 12.3.3"
gem "rspec", "~> 3.0"
gem "sinatra"
gem "test-unit", "~> 3.4.4"
gem "timecop"
gem "typhoeus", ">= 1.1.0"
gem "webmock"
gem "webrick"
gem "yard"
