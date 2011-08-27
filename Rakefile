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
  t.ruby_opts = "-w -r./spec/capture_warnings"

  # I'm not sure why, but bundler seems to silence warnings...
  t.skip_bundler = true

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

unless RUBY_VERSION == '1.8.6'
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new
end

task :default => [:spec, :cucumber]

namespace :ci do
  desc "Sets things up for a ci build on travis-ci.org"
  task :setup do
    ENV['TRAVIS'] = 'true'
    sh "git submodule init"
    sh "git submodule update"
  end

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = true
    t.ruby_opts = "-w -r./spec/capture_warnings"
    # I'm not sure why, but bundler seems to silence warnings...
    t.skip_bundler = true
    t.rspec_opts = %w[--format progress --backtrace]
  end

  ci_tasks = [:setup, :spec]
  ci_tasks << :cucumber if %w[ 1.8.7 1.9.2 1.9.3 ].include?(RUBY_VERSION) && (!defined?(RUBY_ENGINE) || RUBY_ENGINE == 'ruby')
  desc "Run a ci build"
  task :build => ci_tasks
end

def ensure_relish_doc_symlinked(filename)
  from_filename = filename.dup
  from_filename << '.md' unless filename =~ /\.md$/
  from = File.expand_path("../features/#{from_filename}", __FILE__)
  to = File.expand_path("../#{filename}", __FILE__)

  if File.symlink?(from)
    return if File.readlink(from) == to

    # delete the old symlink
    File.unlink(from)
  end

  FileUtils.ln_s to, from
end

desc "Push cukes to relishapp using the relish-client-gem"
task :relish do
  %w[ README.md CHANGELOG.md LICENSE ].each do |file|
    ensure_relish_doc_symlinked(file)
  end

  require 'vcr/version'
  sh "relish versions:add myronmarston/vcr:#{VCR.version}" if ENV['NEW_RELISH_RELEASE']
  sh "relish push vcr:#{VCR.version}"
end

task :prep_relish_release do
  ENV['NEW_RELISH_RELEASE'] = 'true'
end

task :require_ruby_18 do
  raise "This must be run on Ruby 1.8" unless RUBY_VERSION =~ /^1\.8/
end

task :release => [:require_ruby_18, :prep_relish_release, :relish]

# For gem-test: http://gem-testers.org/
task :test => :spec

task :fix_should_eq do
  Dir["spec/**/*.rb"].each do |spec_file|
    contents = File.read(spec_file)
    contents.gsub!(/should == (.*)$/, 'should eq(\1)')
    File.open(spec_file, 'w') { |f| f.write(contents) }
  end
end
