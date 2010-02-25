$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'vcr'

begin
  require 'ruby-debug'
  Debugger.start
  Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)
rescue LoadError
  # ruby-debug wasn't available so neither can the debugging be
end

require 'spec/expectations'

VCR.config do |c|
  c.cache_dir = File.join(File.dirname(__FILE__), '..', 'fixtures', 'vcr_sandboxes', RUBY_VERSION)
end

VCR.module_eval do
  def self.completed_cucumber_scenarios
    @completed_cucumber_scenarios ||= []
  end

  class << self
    attr_accessor :current_cucumber_scenario
  end
end

After do |scenario|
  VCR.completed_cucumber_scenarios << scenario
end

Before do |scenario|
  VCR.current_cucumber_scenario = scenario
  temp_dir = File.join(VCR::Config.cache_dir, 'temp')
  FileUtils.rm_rf(temp_dir) if File.exist?(temp_dir)
end

Before('@copy_not_the_real_response_to_temp') do
  orig_file = File.join(VCR::Config.cache_dir, 'not_the_real_response.yml')
  temp_file = File.join(VCR::Config.cache_dir, 'temp', 'not_the_real_response.yml')
  FileUtils.mkdir_p(File.join(VCR::Config.cache_dir, 'temp'))
  FileUtils.cp orig_file, temp_file
end

at_exit do
  %w(record_sandbox1 record_sandbox2).each do |tag|
    cache_file = File.join(VCR::Config.cache_dir, 'cucumber_tags', "#{tag}.yml")
    FileUtils.rm_rf(cache_file) if File.exist?(cache_file)
  end
end

VCR.cucumber_tags do |t|
  t.tags '@record_sandbox1', '@record_sandbox2', :record => :unregistered
  t.tags '@replay_sandbox1', '@replay_sandbox2', :record => :none
end