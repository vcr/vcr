require 'rubygems'

if RUBY_VERSION =~ /1.9/ && RUBY_ENGINE == 'ruby'
  require 'simplecov'

  SimpleCov.start do
    add_filter "/spec"
    add_filter "/features"

    # internet_connection mostly contains logic copied from the ruby 1.8.7
    # stdlib for which I haven't written tests.
    add_filter "internet_connection"
  end

  SimpleCov.at_exit do
    File.open(File.join(SimpleCov.coverage_path, 'coverage_percent.txt'), 'w') do |f|
      f.write SimpleCov.result.covered_percent
    end
    SimpleCov.result.format!
  end
end

using_git = File.exist?(File.expand_path('../../.git/', __FILE__))
if using_git
  require 'bundler'
  Bundler.setup
end

require 'rspec'

require "support/fixnum_extension.rb"
require "support/limited_uri.rb"
require "support/http_library_adapters.rb"
require "support/ruby_interpreter.rb"
require "support/shared_example_groups/hook_into_http_library.rb"
require "support/shared_example_groups/request_hooks.rb"
require "support/sinatra_app.rb"
require "support/vcr_localhost_server.rb"
require "support/vcr_stub_helpers.rb"

require 'vcr'
require 'monkey_patches'

module VCR
  SPEC_ROOT = File.dirname(__FILE__)

  def reset!(hook = :fakeweb)
    instance_variables.each do |ivar|
      instance_variable_set(ivar, nil)
    end
    configuration.hook_into hook if hook
  end
end

RSpec.configure do |config|
  config.order = :rand
  config.color_enabled = true
  config.debug = (using_git && RUBY_INTERPRETER == :mri && !%w[ 1.9.3 ].include?(RUBY_VERSION) && !ENV['CI'])
  config.treat_symbols_as_metadata_keys_with_true_values = true

  tmp_dir = File.expand_path('../../tmp/cassette_library_dir', __FILE__)
  config.before(:each) do
    unless example.metadata[:skip_vcr_reset]
      VCR.reset!
      VCR.configuration.cassette_library_dir = tmp_dir
      VCR.configuration.uri_parser = LimitedURI
    end
  end

  config.after(:each) do
    FileUtils.rm_rf tmp_dir
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

VCR::SinatraApp.boot
