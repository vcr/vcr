source :rubygems

gem 'typhoeus', :git => "https://github.com/typhoeus/typhoeus.git"
gem 'webmock',  :git => "https://github.com/i0rek/webmock.git", :branch => "typhoeus_0.5.0"
gem 'faraday',  :git => "https://github.com/i0rek/faraday.git", :branch => "typhoeus_0.5.0"

gemspec

group :development do
  platforms :jruby do
    gem 'jruby-openssl'
  end
end

gem 'yard'

# Additional gems that are useful, but not required for development.
group :extras do
  gem 'relish', '~> 0.6'
  gem 'fuubar'
  gem 'fuubar-cucumber'

  gem 'redcarpet', '~> 1.17.2'
  gem 'github-markup'

  platforms :mri_18, :jruby do
    gem 'ruby-debug'
  end

  platforms :mri_19 do
    gem 'ruby-debug19'
  end unless RUBY_VERSION == '1.9.3'
end

