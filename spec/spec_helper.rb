require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require "pry"
require "rspec"
require "vcr"
require "date"
require "forwardable"
require "uri"
require "vcr/util/internet_connection"
require_relative "support/fixnum_extension"
require_relative "support/limited_uri"
require_relative "support/ruby_interpreter"
require_relative "support/shared_example_groups/hook_into_http_library"
require_relative "support/shared_example_groups/request_hooks"
require_relative "support/vcr_stub_helpers"
require_relative "support/vcr_localhost_server"
require_relative "support/sinatra_app"
require_relative "monkey_patches"
require_relative "support/http_library_adapters"

module VCR
  SPEC_ROOT = File.dirname(File.expand_path('.', __FILE__))

  def reset!(hook = :fakeweb)
    instance_variables.each do |ivar|
      instance_variable_set(ivar, nil)
    end
    initialize_ivars
    configuration.hook_into hook if hook
  end
end

RSpec.configure do |config|
  tmp_dir = File.expand_path('../../tmp/cassette_library_dir', __FILE__)
  config.before(:each) do |example|
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
