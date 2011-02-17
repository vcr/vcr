require 'rubygems'
require 'bundler'
Bundler.setup

require 'rspec'

# Ruby 1.9.1 has a different yaml serialization format.
YAML_SERIALIZATION_VERSION = RUBY_VERSION == '1.9.1' ? '1.9.1' : 'not_1.9.1'

Dir['./spec/support/**/*.rb'].each { |f| require f }

require 'vcr'
require 'monkey_patches'

module VCR
  SPEC_ROOT = File.dirname(__FILE__)

  module Config
    def reset!(stubbing_lib = :fakeweb)
      self.default_cassette_options = { :record => :new_episodes }

      if stubbing_lib
        stub_with stubbing_lib
      else
        http_stubbing_libraries.clear
      end

      clear_hooks
      @ignored_hosts = []

      VCR.instance_eval do
        instance_variables.each { |ivar| remove_instance_variable(ivar) }
      end
    end
  end
end

RSpec.configure do |config|
  config.color_enabled = true
  config.debug = RUBY_INTERPRETER == :mri

  config.before(:each) do
    VCR.turn_on! unless VCR.turned_on?
    VCR.eject_cassette while VCR.current_cassette

    VCR::Config.reset!

    WebMock.allow_net_connect!
    WebMock.reset!

    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry

    VCR::HttpStubbingAdapters::Faraday.reset!
  end

  # Ensure each example uses a different cassette library to keep them isolated.
  config.around(:each) do |example|
    Dir.mktmpdir do |dir|
      VCR::Config.cassette_library_dir = dir
      example.run
    end
  end

  config.after(:each) do
    VCR::HttpStubbingAdapters::Common.adapters.each do |a|
      a.ignored_hosts = []
    end
  end

  config.before(:all, :disable_warnings => true) do
    @orig_std_err = $stderr
    $stderr = StringIO.new
  end

  config.after(:all, :disable_warnings => true) do
    $stderr = @orig_std_err
  end

  config.before(:all, :without_webmock_callbacks => true) do
    @original_webmock_callbacks = ::WebMock::CallbackRegistry.callbacks
    ::WebMock::CallbackRegistry.reset
  end

  config.after(:all, :without_webmock_callbacks => true) do
    @original_webmock_callbacks.each do |cb|
      ::WebMock::CallbackRegistry.add_callback(cb[:options], cb[:block])
    end
  end

  [:all, :vcr].each do |scope|
    config.before(:each, :without_monkey_patches => scope) { MonkeyPatches.disable!(scope) }
    config.after(:each, :without_monkey_patches => scope)  { MonkeyPatches.enable!(scope)  }
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.alias_it_should_behave_like_to :it_performs, 'it performs'
end

http_stubbing_dir = File.join(File.dirname(__FILE__), '..', 'lib', 'vcr', 'http_stubbing_adapters')
Dir[File.join(http_stubbing_dir, '*.rb')].each do |file|
  next if RUBY_INTERPRETER != :mri && file =~ /(typhoeus)/
  require "vcr/http_stubbing_adapters/#{File.basename(file)}"
end
