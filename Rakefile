require 'rubygems'
require 'rake'
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run all examples using rcov"
RSpec::Core::RakeTask.new :rcov => :cleanup_rcov_files do |t|
  t.rcov = true
  t.rcov_opts =  %[-Ilib -Ispec --exclude "spec/*,gems/*" --text-report --sort coverage --aggregate coverage.data]
end

task :cleanup_rcov_files do
  rm_rf 'coverage.data'
end

begin
  permutations = {
    'fakeweb' => %w( net/http ),
    'webmock' => %w( net/http httpclient patron em-http-request )
  }

  require 'cucumber/rake/task'
  namespace :features do
    permutations.each do |http_stubbing_adapter, http_libraries|
      features_subtasks = []

      namespace http_stubbing_adapter do
        http_libraries.each do |http_lib|
          next if RUBY_PLATFORM =~ /java/ && %w( patron em-http-request ).include?(http_lib)

          sanitized_http_lib = http_lib.gsub('/', '_')
          features_subtasks << "features:#{http_stubbing_adapter}:#{sanitized_http_lib}"

          task "#{sanitized_http_lib}_prep" do
            ENV['HTTP_STUBBING_ADAPTER'] = http_stubbing_adapter
            ENV['HTTP_LIB'] = http_lib
          end

          Cucumber::Rake::Task.new(
            { sanitized_http_lib => "#{features_subtasks.last}_prep" },
            "Run the features using #{http_stubbing_adapter} and #{http_lib}") do |t|
              t.cucumber_opts = ['--format', 'progress', '--tags', "@#{http_stubbing_adapter},@all_http_libs,@#{sanitized_http_lib}"]

              # disable scenarios on heroku that can't pass due to heroku's restrictions
              t.cucumber_opts += ['--tags', '~@spawns_localhost_server'] if ENV.keys.include?('HEROKU_SLUG')
          end
        end
      end

      desc "Run the features using #{http_stubbing_adapter} and each of #{http_stubbing_adapter}'s supported http libraries"
      task http_stubbing_adapter => features_subtasks
    end
  end

  desc "Run the features using each supported permutation of http stubbing library and http library."
  task :features => permutations.keys.map { |a| "features:#{a}" }
rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end

task :default => [:spec, :features]

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "vcr #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

def gemspec
  @gemspec ||= begin
    file = File.expand_path('../vcr.gemspec', __FILE__)
    eval(File.read(file), binding, file)
  end
end

begin
  require 'rake/gempackagetask'
rescue LoadError
  task(:gem) { $stderr.puts '`gem install rake` to package gems' }
else
  Rake::GemPackageTask.new(gemspec) do |pkg|
    pkg.gem_spec = gemspec
  end
  task :gem => :gemspec
end

desc "install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
end

desc "validate the gemspec"
task :gemspec do
  gemspec.validate
end

task :package => :gemspec
