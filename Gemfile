source :rubygems
gemspec

group :development do
  # patron and em-http-request can't install on JRuby, so we have to limit their platform here.
  platforms :ruby do
    gem 'patron',           '~> 0.4.6'
    gem 'em-http-request',  '~> 0.2.7'
    gem 'curb',             '~> 0.7.8'
  end

  gem 'webmock', :git => 'git://github.com/bblimke/webmock.git'
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

