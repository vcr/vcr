using_git = File.exist?(File.expand_path('../.git/', __FILE__))

if using_git
  require 'bundler/setup'
  require 'bundler/gem_helper'
  Bundler::GemHelper.install_tasks
  require 'appraisal'
end

require 'rake'
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false

  # we require spec_helper so we don't get an RSpec warning about
  # examples being defined before configuration.
  t.ruby_opts = "-I./spec -r./spec/capture_warnings -rspec_helper"
  t.rspec_opts = %w[--format progress] if (ENV['FULL_BUILD'] || !using_git)
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new

task :default => [:submodules, :spec, :cucumber]

desc "Ensures we keep up 100% YARD coverage"
task :yard_coverage do
  coverage_stats = `yard stats --list-undoc 2>&1`
  puts coverage_stats
  if coverage_stats.include?('100.00% documented')
    puts "\nNice work! 100% documentation coverage"
  else
    raise "Documentation coverage is less than 100%"
  end
end

desc "Checks the spec coverage and fails if it is less than 100%"
task :check_code_coverage do
  if RUBY_VERSION.to_f < 1.9 || RUBY_ENGINE != 'ruby'
    puts "Cannot check code coverage--simplecov is not supported on this platform"
  else
    percent = File.read("./coverage/coverage_percent.txt").to_f
    if percent < 98.0
      abort "Spec coverage was not high enough: #{percent.round(2)}%"
    else
      puts "Nice job! Spec coverage is still above 98%"
    end
  end
end

desc "Checkout git submodules"
task :submodules do
  sh "git submodule sync"
  sh "git submodule update --init --recursive"
end

namespace :ci do
  desc "Sets things up for a ci build on travis-ci.org"
  task :setup => :submodules do
    ENV['TRAVIS'] = 'true'
  end

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = true

    # we require spec_helper so we don't get an RSpec warning about
    # examples being defined before configuration.
    t.ruby_opts = "-w -I./spec -r./spec/capture_warnings -rspec_helper"
    t.rspec_opts = %w[--format progress --backtrace]
  end

  desc "Run a ci build"
  task :build => [:setup, :spec, :cucumber, :yard_coverage, :check_code_coverage]
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
  unless ENV['SKIP_RELISH']
    %w[ README.md CHANGELOG.md Upgrade.md LICENSE CONTRIBUTING.md].each do |file|
      ensure_relish_doc_symlinked(file)
    end

    require 'vcr/version'
    sh "relish versions:add vcr/vcr:#{VCR.version}" if ENV['NEW_RELISH_RELEASE'] == 'true'
    sh "relish push vcr/vcr:#{VCR.version}"
  end
end

task :prep_relish_release do
  ENV['NEW_RELISH_RELEASE'] ||= 'true'
end

task :release => [:prep_relish_release, :relish]

# For gem-test: http://gem-testers.org/
task :test => :spec

load './lib/vcr/tasks/vcr.rake'
namespace :vcr do
  task :reset_spec_cassettes do
    ENV['DIR'] = 'spec/fixtures'
    def VCR.version; "2.0.0"; end
    sh "git checkout v2.0.0.beta1 -- spec/fixtures"
  end

  task :migrate_cassettes => :reset_spec_cassettes
end

desc "Migrate cucumber cassettes"
task :migrate_cucumber_cassettes do
  require 'vcr'
  require 'ruby-debug'

  VCR.configure do |c|
    c.cassette_library_dir = 'tmp/migrate'
    c.default_cassette_options = { :serialize_with => :syck }
  end

  # We want 2.0.0 in the cucumber cassettes instead of 2.0.0.rc1
  def VCR.version
    "2.0.0"
  end

  Dir["features/**/*.feature"].each do |feature_file|
    # The ERB cassettes can't be migrated automatically.
    next if feature_file.include?('dynamic_erb')

    puts " - Migrating #{feature_file}"
    contents = File.read(feature_file)

    # http://rubular.com/r/gjzkoaYX2O
    contents.scan(/:\n^\s+"""\n([\s\S]+?)"""/).each do |captures|
      capture = captures.first
      indentation = capture[/^ +/]
      cassette_yml = capture.gsub(/^#{indentation}/, '')
      new_yml = nil

      file_name = "tmp/migrate/cassette.yml"
      File.open(file_name, 'w') { |f| f.write(cassette_yml) }
      cassette = VCR::Cassette.new('cassette')

      hash = begin
        cassette.serializable_hash
      rescue => e
        puts "   Skipping #{capture[0, 80]}"
        next
      end

      new_yml = VCR::Cassette::Serializers::Syck.serialize(hash)

      new_yml.gsub!(/^/, indentation)
      new_yml << indentation
      new_yml.gsub!(/^\s+\n(\s+response:)/, '\1')
      contents.gsub!(capture, new_yml)
    end

    File.open(feature_file, 'w') { |f| f.write(contents) }
  end
end

desc "Run the last cuke directly"
task :run_last_cuke do
  command = ENV.fetch('CMD') do
    raise "Must pass CMD"
  end

  Dir.chdir("tmp/aruba") do
    sh "RUBYOPT='-I.:../../lib -r../../features/support/vcr_cucumber_helpers' ruby #{command}"
  end
end

desc "Boot test app"
task :boot_test_app do
  require './spec/support/vcr_localhost_server'
  require './spec/support/sinatra_app'
  VCR::SinatraApp.boot
  puts "Booted sinatra app on port: #{VCR::SinatraApp.port}"
  loop { }
  puts "Shutting down."
end
