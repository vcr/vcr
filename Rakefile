require 'bundler'
require 'bundler/setup'
Bundler::GemHelper.install_tasks

require 'rake'
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  #t.rspec_opts = %w[--format documentation]
end

desc "Run all examples using rcov"
RSpec::Core::RakeTask.new :rcov => :cleanup_rcov_files do |t|
  t.rcov = true
  t.rcov_opts =  %[-Ilib -Ispec --exclude "spec/*,gems/*" --text-report --sort coverage --aggregate coverage.data]
end

task :cleanup_rcov_files do
  rm_rf 'coverage.data'
end

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

task :default => [:spec, :features]

