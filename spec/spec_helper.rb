require 'rubygems'
require 'bundler'
Bundler.setup

require 'rspec'

# Ruby 1.9.1 has a different yaml serialization format.
YAML_SERIALIZATION_VERSION = RUBY_VERSION == '1.9.1' ? '1.9.1' : 'not_1.9.1'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

require 'vcr'
require 'monkey_patches'

RSpec.configure do |config|
  config.extend TempCassetteLibraryDir
  config.extend DisableWarnings
  config.extend MonkeyPatches::RSpecMacros
  config.extend WebMockMacros

  config.color_enabled = true
  config.debug = RUBY_INTERPRETER == :mri

  config.before(:each) do
    VCR::Config.default_cassette_options = { :record => :new_episodes }
    VCR::Config.http_stubbing_library = :fakeweb

    WebMock.allow_net_connect!
    WebMock.reset_webmock

    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.alias_it_should_behave_like_to :it_performs, 'it performs'
end

