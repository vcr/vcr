source :rubygems
gemspec

group :development do
  # patron and em-http-request can't install on JRuby, so we have to limit their platform here.
  platforms :ruby do
    gem 'patron',           '~> 0.4.6'
    gem 'em-http-request',  '~> 0.2.7'
  end

  # I've got a fix that allows a stubbed object to be serialized properly.  It's waiting to be merged in to rspec-mocks.
  gem 'rspec-mocks', :git => 'git://github.com/myronmarston/rspec-mocks.git', :branch => 'fix_yaml_serialization'
  gem 'rspec-core',  :git => 'git://github.com/rspec/rspec-core.git'
end

# Additional gems that are useful, but not required for development.
group :extras do
  platforms :mri do
    gem 'rcov'
  end

  platforms :mri_18 do
    gem 'ruby-debug'
  end

  platforms :mri_19 do
    gem 'ruby-debug19'
    gem 'ruby-debug-base19', '0.11.23'
  end
end

