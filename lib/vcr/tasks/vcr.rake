require 'vcr/task_runner'

namespace :vcr do
  desc 'Migrates your VCR cassettes in DIR from the 0.3.1 format to the 0.4+ format'
  task :migrate_cassettes do
    raise "You must pass the cassette library directory as DIR" if ENV['DIR'].to_s == ''
    VCR::TaskRunner.migrate_cassettes(ENV['DIR'])
  end
end
