#!/usr/bin/env rake

require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run all the tests in spec"
RSpec::Core::RakeTask.new(:spec)

using_git = File.exist?(File.expand_path('../.git/', __FILE__))

require "cucumber/rake/task"
Cucumber::Rake::Task.new

desc "Default: run tests"
task default: [:spec, :cucumber]

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
