require 'vcr/util/regexes'
require 'vcr/util/variable_args_block_caller'
require 'vcr/util/yaml'

require 'vcr/cassette'
require 'vcr/configuration'
require 'vcr/request_matcher'
require 'vcr/request_matcher_registry'
require 'vcr/version'

require 'vcr/deprecations/vcr'

require 'vcr/http_stubbing_adapters/common'
require 'vcr/structs/http_interaction'

module VCR
  include VariableArgsBlockCaller
  extend self

  autoload :BasicObject,        'vcr/util/basic_object'
  autoload :CucumberTags,       'vcr/test_frameworks/cucumber'
  autoload :InternetConnection, 'vcr/util/internet_connection'
  autoload :RSpec,              'vcr/test_frameworks/rspec'

  LOCALHOST_ALIASES = %w( localhost 127.0.0.1 0.0.0.0 )

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

  def request_matcher_registry
    @request_matcher_registry ||= RequestMatcherRegistry.new
  end

  def configuration
    @configuration ||= Configuration.new
  end

  def configure
    yield configuration
    http_stubbing_adapter.check_version!
    http_stubbing_adapter.set_http_connections_allowed_to_default
    http_stubbing_adapter.ignored_hosts = VCR.configuration.ignored_hosts
  end

  def cucumber_tags(&block)
    main_object = eval('self', block.binding)
    yield VCR::CucumberTags.new(main_object)
  end

  def http_stubbing_adapter
    @http_stubbing_adapter ||= begin
      if [:fakeweb, :webmock].all? { |l| VCR.configuration.http_stubbing_libraries.include?(l) }
        raise ArgumentError.new("You have configured VCR to use both :fakeweb and :webmock.  You cannot use both.")
      end

      adapters = VCR.configuration.http_stubbing_libraries.map { |l| adapter_for(l) }
      raise ArgumentError.new("The http stubbing library is not configured.") if adapters.empty?
      adapter = HttpStubbingAdapters::MultiObjectProxy.for(*adapters)
      adapter.after_adapters_loaded
      adapter
    end
  end

  def record_http_interaction(interaction)
    return unless cassette = current_cassette
    return if VCR.configuration.uri_should_be_ignored?(interaction.uri)

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

    VCR.http_stubbing_adapter.http_connections_allowed = true
    @turned_off = true
  end

  def turn_on!
    VCR.http_stubbing_adapter.set_http_connections_allowed_to_default
    @turned_off = false
  end

  def turned_on?
    !@turned_off
  end

  def ignore_cassettes?
    @ignore_cassettes
  end

  private

  def adapter_for(lib)
    case lib
      when :excon;    HttpStubbingAdapters::Excon
      when :fakeweb;  HttpStubbingAdapters::FakeWeb
      when :faraday;  HttpStubbingAdapters::Faraday
      when :typhoeus; HttpStubbingAdapters::Typhoeus
      when :webmock;  HttpStubbingAdapters::WebMock
      else raise ArgumentError.new("#{lib.inspect} is not a supported HTTP stubbing library.")
    end
  end

  def cassettes
    @cassettes ||= []
  end

  def initialize_ivars
    @turned_off = false
  end

  initialize_ivars # to avoid warnings
end
