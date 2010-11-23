source :rubygems
gemspec

group :development do
  # patron and em-http-request can't install on JRuby, so we have to limit their platform here.
  platforms :ruby do
    gem 'patron',           '~> 0.4.6'
    gem 'em-http-request',  '~> 0.2.7'
    gem 'curb',             '~> 0.7.8'
    gem 'typhoeus',         '~> 0.2.0'
  end

  platforms :jruby do
    gem 'jruby-openssl'
  end

  gem 'shoulda'
end

# Additional gems that are useful, but not required for development.
group :extras do
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'growl'
  gem 'relish'

  platforms :mri do
    gem 'rcov'
    gem 'rb-fsevent'
  end

  platforms :mri_18 do
    gem 'ruby-debug'
  end

  platforms :mri_19 do
    gem 'ruby-debug19'
    gem 'ruby-debug-base19', '0.11.23'
  end
end

