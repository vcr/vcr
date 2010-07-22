source :rubygems

group :development do
  gem 'rspec',              '~> 1.3.0'
  gem 'cucumber',           '>= 0.8.5'
  gem 'fakeweb',            '~> 1.2.8'
  gem 'webmock',            '~> 1.3.0'
  gem 'httpclient',         '~> 2.1.5.2'
  gem 'capybara',           '~> 0.3.9'
  gem 'rack',               '1.2.0'
  gem 'rake',               '~> 0.8.7'

  platforms :ruby do
    gem 'patron',           '~> 0.4.6'
    gem 'em-http-request',  '~> 0.2.7'
  end
end

group :test do
  platforms :ruby_18 do
    gem 'ruby-debug'
  end

  platforms :ruby_19 do
    gem 'ruby-debug19'
  end
end

