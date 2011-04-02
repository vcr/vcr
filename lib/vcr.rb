require 'vcr/util/regexes'
require 'vcr/util/variable_args_block_caller'
require 'vcr/util/yaml'

require 'vcr/cassette'
require 'vcr/config'
require 'vcr/request_matcher'
require 'vcr/version'

require 'vcr/http_stubbing_adapters/common'

require 'vcr/deprecations/cassette'
require 'vcr/deprecations/config'
require 'vcr/deprecations/http_stubbing_adapters/common'

require 'vcr/structs/normalizers/body'
require 'vcr/structs/normalizers/header'
require 'vcr/structs/normalizers/status_message'
require 'vcr/structs/normalizers/uri'
require 'vcr/structs/http_interaction'
require 'vcr/structs/request'
require 'vcr/structs/response'
require 'vcr/structs/response_status'

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
    unless turned_on?
      raise TurnedOffError.new("VCR is turned off.  You must turn it on before you can insert a cassette.")
    end

    if cassettes.any? { |c| c.name == name }
      raise ArgumentError.new("There is already a cassette with the same name (#{name}).  You cannot nest multiple cassettes with the same name.")
    end

    cassette = Cassette.new(name, options)
    cassettes.push(cassette)
    cassette
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

  def config
    yield VCR::Config
    http_stubbing_adapter.check_version!
    http_stubbing_adapter.set_http_connections_allowed_to_default
    http_stubbing_adapter.ignored_hosts = VCR::Config.ignored_hosts
  end

  def cucumber_tags(&block)
    main_object = eval('self', block.binding)
    yield VCR::CucumberTags.new(main_object)
  end

  def http_stubbing_adapter
    @http_stubbing_adapter ||= begin
      if [:fakeweb, :webmock].all? { |l| VCR::Config.http_stubbing_libraries.include?(l) }
        raise ArgumentError.new("You have configured VCR to use both :fakeweb and :webmock.  You cannot use both.")
      end

      adapters = VCR::Config.http_stubbing_libraries.map { |l| adapter_for(l) }
      raise ArgumentError.new("The http stubbing library is not configured.") if adapters.empty?
      HttpStubbingAdapters::MultiObjectProxy.for(*adapters)
    end
  end

  def record_http_interaction(interaction)
    return unless cassette = current_cassette
    return if VCR::Config.uri_should_be_ignored?(interaction.uri)

    cassette.record_http_interaction(interaction)
  end

  def turned_off
    turn_off!

    begin
      yield
    ensure
      turn_on!
    end
  end

  def turn_off!
    if VCR.current_cassette
      raise CassetteInUseError.new("A VCR cassette is currently in use.  You must eject it before you can turn VCR off.")
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
end
