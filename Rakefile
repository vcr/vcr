using_git = File.exist?(File.expand_path('../.git/', __FILE__))

if using_git
  require 'bundler'
  require 'bundler/setup'
  Bundler::GemHelper.install_tasks
end

require 'rake'
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
  t.skip_bundler = true unless using_git
  t.rspec_opts = %w[--format progress] if (ENV['FULL_BUILD'] || !using_git)
end

desc "Run all examples using rcov"
RSpec::Core::RakeTask.new :rcov => :cleanup_rcov_files do |t|
  t.rcov = true
  t.rcov_opts =  %[-Ilib -Ispec --exclude "spec/*,gems/*,ping,basic_object" --text-report --sort coverage --aggregate coverage.data]
end

task :cleanup_rcov_files do
  rm_rf 'coverage.data'
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new

task :default => [:spec, :cucumber]

namespace :ci do
  desc "Sets things up for a ci build on travis-ci.org"
  task :setup do
    sh "git submodule init"
    sh "git submodule update"
  end

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = true
    t.rspec_opts = %w[--format progress --backtrace]
  end

  desc "Run a ci build"
  task :build => [:setup, :spec, :cucumber]
end

desc "Push cukes to relishapp using the relish-client-gem"
task :relish do
  require 'vcr/version'
  sh "relish versions:add myronmarston/vcr:#{VCR.version}"
  sh "relish push vcr:#{VCR.version}"
end

task :release => :relish

# For gem-test: http://gem-testers.org/
task :test => :spec
