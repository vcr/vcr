require 'rubygems'

using_git = File.exist?(File.expand_path('../../.git/', __FILE__))
if using_git
  require 'bundler'
  Bundler.setup
end

require 'rspec'

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
      VCR.send(:initialize_ivars)
    end
  end
end

RSpec.configure do |config|
  config.color_enabled = true
  config.debug = (using_git && RUBY_INTERPRETER == :mri && !%w[ 1.9.3 ].include?(RUBY_VERSION) && !ENV['CI'])
  config.treat_symbols_as_metadata_keys_with_true_values = true

  tmp_dir = File.expand_path('../../tmp/cassette_library_dir', __FILE__)
  config.before(:each) do
    VCR::Config.cassette_library_dir = tmp_dir
    VCR.turn_on! unless VCR.turned_on?
    VCR.eject_cassette while VCR.current_cassette

    VCR::Config.reset!

    WebMock.allow_net_connect!
    WebMock.reset!

    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry

    VCR::HttpStubbingAdapters::Faraday.reset!
    VCR::HttpStubbingAdapters::Excon.reset!
  end

  config.after(:each) do
    FileUtils.rm_rf tmp_dir
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

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.alias_it_should_behave_like_to :it_performs, 'it performs'
end

http_stubbing_dir = File.join(File.dirname(__FILE__), '..', 'lib', 'vcr', 'http_stubbing_adapters')
Dir[File.join(http_stubbing_dir, '*.rb')].each do |file|
  next if RUBY_INTERPRETER != :mri && file =~ /(typhoeus)/
  require "vcr/http_stubbing_adapters/#{File.basename(file)}"
end
