$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../spec/support')

if ENV['HTTP_STUBBING_ADAPTER'].to_s == ''
  ENV['HTTP_STUBBING_ADAPTER'] = 'fakeweb'
  warn "Using FakeWeb for VCR's cucumber features since the adapter was not specified.  Set HTTP_STUBBING_ADAPTER to specify."
end

if ENV['HTTP_LIB'].to_s == ''
  ENV['HTTP_LIB'] = 'net/http'
  warn "Using Net::HTTP for VCR's cucumber features since the HTTP library was not specified.  Set HTTP_LIB to specify."
end

# The HTTP library must be loaded before VCR since WebMock looks for the presence of the HTTB library class constant
# to decide whether or not to hook into it.
require ENV['HTTP_LIB']
require 'http_library_adapters'
World(HTTP_LIBRARY_ADAPTERS[ENV['HTTP_LIB']])

puts "\n\n---------------- Running features using #{ENV['HTTP_STUBBING_ADAPTER']} and #{ENV['HTTP_LIB']} -----------------\n"

require 'vcr'
require 'vcr_localhost_server'

require 'rubygems'
require 'bundler'
Bundler.setup

begin
  require 'ruby-debug'
  Debugger.start
  Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)
rescue LoadError
  # ruby-debug wasn't available so neither can the debugging be
end unless RUBY_VERSION > '1.9.1' # ruby-debug doesn't work on 1.9.2 yet

# Ruby 1.9.1 has a different yaml serialization format.
YAML_SERIALIZATION_VERSION = RUBY_VERSION == '1.9.1' ? '1.9.1' : 'not_1.9.1'

VCR.config do |c|
  c.cassette_library_dir = File.join(File.dirname(__FILE__), '..', 'fixtures', 'vcr_cassettes', YAML_SERIALIZATION_VERSION)
  c.http_stubbing_library = ENV['HTTP_STUBBING_ADAPTER'].to_sym
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
  if raised_error = (@http_requests || {}).values.flatten.detect { |result| result.is_a?(Exception) && result.message !~ /VCR/ }
    raise raised_error
  end
  VCR.completed_cucumber_scenarios << scenario
end

Before do |scenario|
  VCR::Config.ignore_localhost = false

  VCR.current_cucumber_scenario = scenario
  temp_dir = File.join(VCR::Config.cassette_library_dir, 'temp')
  FileUtils.rm_rf(temp_dir) if File.exist?(temp_dir)
end

%w[not_the_real_response record_all].each do |cassette|
  Before("@copy_#{cassette}_to_temp") do
    orig_file = File.join(VCR::Config.cassette_library_dir, "#{cassette}.yml")
    temp_file = File.join(VCR::Config.cassette_library_dir, 'temp', "#{cassette}.yml")
    FileUtils.mkdir_p(File.join(VCR::Config.cassette_library_dir, 'temp'))
    FileUtils.cp orig_file, temp_file
  end
end

Before('@create_replay_localhost_cassette') do
  orig_file = File.join(VCR::Config.cassette_library_dir, 'replay_localhost_cassette.yml')
  temp_file = File.join(VCR::Config.cassette_library_dir, 'temp', 'replay_localhost_cassette.yml')
  FileUtils.mkdir_p(File.join(VCR::Config.cassette_library_dir, 'temp'))

  # the port varies each time, so create a temp cassette with the correct port.
  port = static_rack_server('localhost response').port

  interactions = YAML.load(File.read(orig_file))
  interactions.each do |i|
    uri = URI.parse(i.request.uri)
    uri.port = port
    i.request.uri = uri.to_s
  end

  File.open(temp_file, 'w') { |f| f.write interactions.to_yaml }
end

at_exit do
  %w(record_cassette1 record_cassette2).each do |tag|
    file = File.join(VCR::Config.cassette_library_dir, 'cucumber_tags', "#{tag}.yml")
    FileUtils.rm_rf(file) if File.exist?(file)
  end
end

VCR.cucumber_tags do |t|
  t.tags '@record_cassette1', '@record_cassette2', :record => :new_episodes
  t.tags '@replay_cassette1', '@replay_cassette2', '@replay_cassette3', '@regex_cassette', :record => :none
end
