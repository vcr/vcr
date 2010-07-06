source :rubygems

group :development do
  gem 'rspec',              '~> 1.3.0'
  gem 'cucumber',           '>= 0.6.4'
  gem 'fakeweb',            '~> 1.2.8'
  gem 'webmock',            '~> 1.3.0'
  gem 'httpclient',         '~> 2.1.5.2'
  gem 'patron',             '~> 0.4.6' unless RUBY_PLATFORM == 'java'
  gem 'em-http-request' ,   '~> 0.2.7' unless RUBY_PLATFORM == 'java'
  gem 'capybara',           '~> 0.3.9'
  gem 'rack',               '1.2.0'
end

group :test do
  unless RUBY_PLATFORM == 'java'
    if RUBY_VERSION =~ /1\.9/
      gem 'ruby-debug19'
    else
      gem 'ruby-debug'
    end
  end
end

