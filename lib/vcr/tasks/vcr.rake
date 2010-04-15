require 'vcr/task_runner'

namespace :vcr do
  task :migrate_cassettes do
    raise "You must pass the cassette library directory as DIR" if ENV['DIR'].to_s == ''
    VCR::TaskRunner(ENV['DIR'])
  end
end
