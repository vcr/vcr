require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "vcr"
    gem.summary = %Q{Use VCR to record HTTP responses and replay them using fakeweb.}
    gem.description = %Q{VCR provides helpers to record HTTP requests for URIs that are not registered with fakeweb, and replay them later.  It works with any ruby testing framework, and provides built-in support for cucumber.}
    gem.email = "myron.marston@gmail.com"
    gem.homepage = "http://github.com/myronmarston/vcr"
    gem.authors = ["Myron Marston"]

    gem.add_dependency 'fakeweb',  '>= 1.2.8'

    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "cucumber", ">= 0.6.1"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies if defined?(Jeweler)

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)

  task :features => :check_dependencies
rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end

task :default => :spec do
  %w( webmock fakeweb ).each do |http_stubbing_adapter|
    puts "\n\n-------------- Running features using #{http_stubbing_adapter} http_stubbing_adapter -----------------\n"
    ENV['HTTP_STUBBING_ADAPTER'] = http_stubbing_adapter
    Rake::Task[:features].execute
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "vcr #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
