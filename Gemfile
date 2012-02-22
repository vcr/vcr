source :rubygems
gemspec

group :development do
  platforms :jruby do
    gem 'jruby-openssl'
  end
end

gem 'yard'

# Additional gems that are useful, but not required for development.
group :extras do
  gem 'guard-rspec'
  gem 'growl'
  gem 'relish', '~> 0.5.0'
  gem 'fuubar'
  gem 'fuubar-cucumber'

  gem 'redcarpet', '~> 1.17.2'
  gem 'github-markup'

  platforms :mri do
    gem 'rb-fsevent'
  end

  platforms :mri_18, :jruby do
    gem 'ruby-debug'
  end

  platforms :mri_19 do
    gem 'ruby-debug19'
  end unless RUBY_VERSION == '1.9.3'
end

