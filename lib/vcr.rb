require 'vcr/util/variable_args_block_caller'
require 'vcr/util/yaml'

require 'vcr/cassette'
require 'vcr/configuration'
require 'vcr/request_matcher_registry'
require 'vcr/request_ignorer'
require 'vcr/version'

require 'vcr/deprecations/vcr'

require 'vcr/http_stubbing_adapters'
require 'vcr/structs/http_interaction'

module VCR
  include VariableArgsBlockCaller
  extend self

  autoload :BasicObject,        'vcr/util/basic_object'
  autoload :CucumberTags,       'vcr/test_frameworks/cucumber'
  autoload :InternetConnection, 'vcr/util/internet_connection'
  autoload :RSpec,              'vcr/test_frameworks/rspec'

  class CassetteInUseError < StandardError; end
  class TurnedOffError < StandardError; end

  module Middleware
    autoload :CassetteArguments, 'vcr/middleware/cassette_arguments'
    autoload :Common,            'vcr/middleware/common'
    autoload :Faraday,           'vcr/middleware/faraday'
    autoload :Rack,              'vcr/middleware/rack'
  end

  def current_cassette
    cassettes.last
  end

  def insert_cassette(name, options = {})
    if turned_on?
      if cassettes.any? { |c| c.name == name }
        raise ArgumentError.new("There is already a cassette with the same name (#{name}).  You cannot nest multiple cassettes with the same name.")
      end

      cassette = Cassette.new(name, options)
      cassettes.push(cassette)
      cassette
    elsif !ignore_cassettes?
      message = "VCR is turned off.  You must turn it on before you can insert a cassette.  " +
                "Or you can use the `:ignore_cassettes => true` option to completely ignore cassette insertions."
      raise TurnedOffError.new(message)
    end
  end

  def eject_cassette
    cassette = cassettes.pop
    cassette.eject if cassette
    cassette
  end

  def use_cassette(*args, &block)
    cassette = insert_cassette(*args)

    begin
      call_block(block, cassette)
    ensure
      eject_cassette
    end
  end

  def http_interactions
    return current_cassette.http_interactions if current_cassette
    VCR::Cassette::HTTPInteractionList::NullList.new
  end

  def real_http_connections_allowed?
    return current_cassette.recording? if current_cassette
    configuration.allow_http_connections_when_no_cassette? || @turned_off
  end

  def request_matchers
    @request_matchers ||= RequestMatcherRegistry.new
  end

  def request_ignorer
    @request_ignorer ||= RequestIgnorer.new
  end

  def http_stubbing_adapters
    @http_stubbing_adapters ||= HTTPStubbingAdapters.new
  end

  def configuration
    @configuration ||= Configuration.new
  end

  def configure
    yield configuration
    configuration.invoke_hook(:after_http_stubbing_adapters_loaded)
  end

  def cucumber_tags(&block)
    main_object = eval('self', block.binding)
    yield VCR::CucumberTags.new(main_object)
  end

  def record_http_interaction(interaction)
    return unless cassette = current_cassette
    return if VCR.request_ignorer.ignore?(interaction.request)

    cassette.record_http_interaction(interaction)
  end

  def turned_off(options = {})
    turn_off!(options)

    begin
      yield
    ensure
      turn_on!
    end
  end

  def turn_off!(options = {})
    if VCR.current_cassette
      raise CassetteInUseError.new("A VCR cassette is currently in use.  You must eject it before you can turn VCR off.")
    end

    @ignore_cassettes = options[:ignore_cassettes]
    invalid_options = options.keys - [:ignore_cassettes]
    if invalid_options.any?
      raise ArgumentError.new("You passed some invalid options: #{invalid_options.inspect}")
    end

    @turned_off = true
  end

  def turn_on!
    @turned_off = false
  end

  def turned_on?
    !@turned_off
  end

  def ignore_cassettes?
    @ignore_cassettes
  end

private

  def cassettes
    @cassettes ||= []
  end

  def initialize_ivars
    @turned_off = false
  end

  initialize_ivars # to avoid warnings
end
