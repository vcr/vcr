require 'vcr/cassette'
require 'vcr/config'
require 'vcr/deprecations'
require 'vcr/request_matcher'
require 'vcr/structs'
require 'vcr/version'
require 'vcr/http_stubbing_adapters/common'

module VCR
  extend self

  autoload :BasicObject,        'vcr/basic_object'
  autoload :CucumberTags,       'vcr/cucumber_tags'
  autoload :InternetConnection, 'vcr/internet_connection'
  autoload :RSpec,              'vcr/rspec'

  LOCALHOST_ALIASES = %w( localhost 127.0.0.1 0.0.0.0 )

  class CassetteInUseError < StandardError; end
  class TurnedOffError < StandardError; end

  module Middleware
    autoload :CassetteArguments, 'vcr/middleware/cassette_arguments'
    autoload :Rack,              'vcr/middleware/rack'
  end

  def current_cassette
    cassettes.last
  end

  def insert_cassette(*args)
    unless turned_on?
      raise TurnedOffError.new("VCR is turned off.  You must turn it on before you can insert a cassette.")
    end

    cassette = Cassette.new(*args)
    cassettes.push(cassette)
    cassette
  end

  def eject_cassette
    cassette = cassettes.pop
    cassette.eject if cassette
    cassette
  end

  def use_cassette(*args)
    insert_cassette(*args)

    begin
      yield
    ensure
      eject_cassette
    end
  end

  def config
    yield VCR::Config
    http_stubbing_adapter.check_version!
    http_stubbing_adapter.set_http_connections_allowed_to_default
    http_stubbing_adapter.ignore_localhost = VCR::Config.ignore_localhost?
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

      adapters = VCR::Config.http_stubbing_libraries.map do |lib|
        case lib
          when :fakeweb;  HttpStubbingAdapters::FakeWeb
          when :webmock;  HttpStubbingAdapters::WebMock
          when :typhoeus; HttpStubbingAdapters::Typhoeus
          else raise ArgumentError.new("#{lib.inspect} is not a supported HTTP stubbing library.")
        end
      end

      raise ArgumentError.new("The http stubbing library is not configured.") if adapters.empty?
      HttpStubbingAdapters::MultiObjectProxy.for(*adapters)
    end
  end

  def record_http_interaction(interaction)
    return unless cassette = current_cassette
    return if http_stubbing_adapter.ignore_localhost? &&
      LOCALHOST_ALIASES.include?(URI.parse(interaction.uri).host)

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

  def cassettes
    @cassettes ||= []
  end
end
