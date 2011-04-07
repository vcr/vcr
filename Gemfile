source :rubygems
gemspec

group :development do
  # patron and em-http-request can't install on JRuby, so we have to limit their platform here.
  platforms :ruby do
    gem 'patron',           '0.4.9'
    gem 'em-http-request',  '~> 0.3.0'
    gem 'curb',             '0.7.8'
    gem 'typhoeus',         '~> 0.2.1'
  end

  platforms :jruby do
    gem 'jruby-openssl'
  end
end

# Additional gems that are useful, but not required for development.
group :extras do
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'growl'
  gem 'relish'
  gem 'fuubar'

  platforms :mri do
    gem 'rcov'
    gem 'rb-fsevent'
  end

  platforms :mri_18 do
    gem 'ruby-debug'
  end

  platforms :mri_19 do
    gem 'linecache19', '0.5.11' # 0.5.12 cannot install on 1.9.1, and 0.5.11 appears to work with both 1.9.1 & 1.9.2
    gem 'ruby-debug19'
    gem 'ruby-debug-base19', RUBY_VERSION == '1.9.1' ? '0.11.23' : '~> 0.11.24'
  end
end

