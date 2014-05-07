require 'forwardable'
require 'vcr/util/logger'
require 'vcr/util/variable_args_block_caller'

require 'vcr/actor'
require 'vcr/cassette'
require 'vcr/cassette/serializers'
require 'vcr/cassette/persisters'
require 'vcr/configuration'
require 'vcr/deprecations'
require 'vcr/errors'
require 'vcr/library_hooks'
require 'vcr/request_ignorer'
require 'vcr/request_matcher_registry'
require 'vcr/structs'
require 'vcr/version'

# @note The main entry point for VCR. This serves as common interface to the singleton
#       instance in vcr_actor. Class methods are being forwarded to there.
#
module VCR
  extend  SingleForwardable
  include Errors

  autoload :CucumberTags,       'vcr/test_frameworks/cucumber'
  autoload :InternetConnection, 'vcr/util/internet_connection'

  module RSpec
    autoload :Metadata,         'vcr/test_frameworks/rspec'
    autoload :Macros,           'vcr/deprecations'
  end

  module Middleware
    autoload :Faraday,          'vcr/middleware/faraday'
    autoload :Rack,             'vcr/middleware/rack'
  end

  def_delegators :vcr_actor,
    :current_cassette, :eject_cassette, :insert_cassette, :request_ignorer, :request_matchers,
    :cassette_persisters, :cassette_serializers, :configuration, :configure, :cucumber_tags,
    :use_cassette, :http_interactions, :library_hooks, :record_http_interaction, :turn_off!,
    :turn_on!, :turned_off, :turned_on?, :real_http_connections_allowed?, :cassettes,
    :initialize_ivars, :wrapped_object


  def self.vcr_actor
    if defined?(Celluloid)
      Celluloid::Actor[:vcr]
    else
      @@vcr_actor ||= VcrActor.new
    end
  end

  def self.cleanup!
    if defined?(Celluloid)
      Celluloid.shutdown
      Celluloid.boot

      VcrSupervisor.run!
    else
      @@vcr_actor = VcrActor.new
    end
  end
end
