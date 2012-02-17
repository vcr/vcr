require 'vcr/util/logger'
require 'vcr/util/variable_args_block_caller'

require 'vcr/cassette'
require 'vcr/cassette/serializers'
require 'vcr/configuration'
require 'vcr/deprecations'
require 'vcr/errors'
require 'vcr/library_hooks'
require 'vcr/request_ignorer'
require 'vcr/request_matcher_registry'
require 'vcr/structs'
require 'vcr/version'

# The main entry point for VCR.
# @note This module is extended onto itself; thus, the methods listed
#  here as instance methods are available directly off of VCR.
module VCR
  include VariableArgsBlockCaller
  include Errors

  extend self

  autoload :CucumberTags,       'vcr/test_frameworks/cucumber'
  autoload :InternetConnection, 'vcr/util/internet_connection'
  autoload :RSpec,              'vcr/test_frameworks/rspec'

  module Middleware
    autoload :Faraday,           'vcr/middleware/faraday'
    autoload :Rack,              'vcr/middleware/rack'
  end

  # The currently active cassette.
  #
  # @return [nil, VCR::Cassette] The current cassette or nil if there is
  #  no current cassette.
  def current_cassette
    cassettes.last
  end

  # Inserts the named cassette using the given cassette options.
  # New HTTP interactions, if allowed by the cassette's `:record` option, will
  # be recorded to the cassette. The cassette's existing HTTP interactions
  # will be used to stub requests, unless prevented by the cassete's
  # `:record` option.
  #
  # @example
  #   VCR.insert_cassette('twitter', :record => :new_episodes)
  #
  #   # ...later, after making an HTTP request:
  #
  #   VCR.eject_cassette
  #
  # @param name [#to_s] The name of the cassette. VCR will sanitize
  #                     this to ensure it is a valid file name.
  # @param options [Hash] The cassette options. The given options will
  #  be merged with the configured default_cassette_options.
  # @option options :record [:all, :none, :new_episodes, :once] The record mode.
  # @option options :erb [Boolean, Hash] Whether or not to evaluate the
  #  cassette as an ERB template. Defaults to false. A hash can be used
  #  to provide the ERB template with local variables.
  # @option options :match_requests_on [Array<Symbol, #call>] List of request matchers
  #  to use to determine what recorded HTTP interaction to replay. Defaults to
  #  [:method, :uri]. The built-in matchers are :method, :uri, :host, :path, :headers
  #  and :body. You can also pass the name of a registered custom request matcher or
  #  any object that responds to #call.
  # @option options :re_record_interval [Integer] When given, the
  #  cassette will be re-recorded at the given interval, in seconds.
  # @option options :tag [Symbol] Used to apply tagged `before_record`
  #  and `before_playback` hooks to the cassette.
  # @option options :tags [Array<Symbol>] Used to apply multiple tags to
  #  a cassette so that tagged `before_record` and `before_playback` hooks
  #  will apply to the cassette.
  # @option options :update_content_length_header [Boolean] Whether or
  #  not to overwrite the Content-Length header of the responses to
  #  match the length of the response body. Defaults to false.
  # @option options :allow_playback_repeats [Boolean] Whether or not to
  #  allow a single HTTP interaction to be played back multiple times.
  #  Defaults to false.
  # @option options :exclusive [Boolean] Whether or not to use only this
  #  cassette and to completely ignore any cassettes in the cassettes stack.
  #  Defaults to false.
  # @option options :serialize_with [Symbol] Which serializer to use.
  #  Valid values are :yaml, :syck, :psych, :json or any registered
  #  custom serializer. Defaults to :yaml.
  # @option options :preserve_exact_body_bytes [Boolean] Whether or not
  #  to base64 encode the bytes of the requests and responses for this cassette
  #  when serializing it. See also `VCR::Configuration#preserve_exact_body_bytes`.
  #
  # @return [VCR::Cassette] the inserted cassette
  #
  # @raise [ArgumentError] when the given cassette is already being used.
  # @raise [VCR::Errors::TurnedOffError] when VCR has been turned off
  #  without using the :ignore_cassettes option.
  # @raise [VCR::Errors::MissingERBVariableError] when the `:erb` option
  #  is used and the ERB template requires variables that you did not provide.
  #
  # @note If you use this method you _must_ call `eject_cassette` when you
  #  are done. It is generally recommended that you use {#use_cassette}
  #  unless your code-under-test cannot be run as a block.
  #
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

  # Ejects the current cassette. The cassette will no longer be used.
  # In addition, any newly recorded HTTP interactions will be written to
  # disk.
  #
  # @return [VCR::Cassette, nil] the ejected cassette if there was one
  def eject_cassette
    cassette = cassettes.last
    cassette.eject if cassette
    cassettes.pop
  end

  # Inserts a cassette using the given name and options, runs the given
  # block, and ejects the cassette.
  #
  # @example
  #   VCR.use_cassette('twitter', :record => :new_episodes) do
  #     # make an HTTP request
  #   end
  #
  # @param (see #insert_cassette)
  # @option (see #insert_cassette)
  # @yield Block to run while this cassette is in use.
  # @yieldparam cassette [(optional) VCR::Cassette] the cassette that has
  #  been inserted.
  # @raise (see #insert_cassette)
  # @return [void]
  # @see #insert_cassette
  # @see #eject_cassette
  def use_cassette(name, options = {}, &block)
    cassette = insert_cassette(name, options)

    begin
      call_block(block, cassette)
    ensure
      eject_cassette
    end
  end

  # @private
  def http_interactions
    return current_cassette.http_interactions if current_cassette
    VCR::Cassette::HTTPInteractionList::NullList
  end

  # @private
  def real_http_connections_allowed?
    return current_cassette.recording? if current_cassette
    configuration.allow_http_connections_when_no_cassette? || @turned_off
  end

  # @return [RequestMatcherRegistry] the request matcher registry
  def request_matchers
    @request_matchers ||= RequestMatcherRegistry.new
  end

  # @private
  def request_ignorer
    @request_ignorer ||= RequestIgnorer.new
  end

  # @private
  def library_hooks
    @library_hooks ||= LibraryHooks.new
  end

  # @private
  def cassette_serializers
    @cassette_serializers ||= Cassette::Serializers.new
  end

  # @return [VCR::Configuration] the VCR configuration.
  def configuration
    @configuration ||= Configuration.new
  end

  # Used to configure VCR.
  #
  # @example
  #    VCR.configure do |c|
  #      c.some_config_option = true
  #    end
  #
  # @yield the configuration block
  # @yieldparam config [VCR::Configuration] the configuration object
  # @return [void]
  def configure
    yield configuration
  end

  # Sets up `Before` and `After` cucumber hooks in order to
  # use VCR with particular cucumber tags.
  #
  # @example
  #   VCR.cucumber_tags do |t|
  #     t.tags "tag1", "tag2"
  #     t.tag "@some_other_tag", :record => :new_episodes
  #   end
  #
  # @yield the cucumber tags configuration block
  # @yieldparam t [VCR::CucumberTags] Cucumber tags config object
  # @return [void]
  # @see VCR::CucumberTags#tags
  def cucumber_tags(&block)
    main_object = eval('self', block.binding)
    yield VCR::CucumberTags.new(main_object)
  end

  # @private
  def record_http_interaction(interaction)
    return unless cassette = current_cassette
    return if VCR.request_ignorer.ignore?(interaction.request)

    cassette.record_http_interaction(interaction)
  end

  # Turns VCR off for the duration of a block.
  #
  # @param (see #turn_off!)
  # @return [void]
  # @raise (see #turn_off!)
  # @see #turn_off!
  # @see #turn_on!
  # @see #turned_on?
  def turned_off(options = {})
    turn_off!(options)

    begin
      yield
    ensure
      turn_on!
    end
  end

  # Turns VCR off, so that it no longer handles every HTTP request.
  #
  # @param options [Hash] hash of options
  # @option options :ignore_cassettes [Boolean] controls what happens when a cassette is
  #  inserted while VCR is turned off. If +true+ is passed, the cassette insertion
  #  will be ignored; otherwise a {VCR::Errors::TurnedOffError} will be raised.
  #
  # @return [void]
  # @raise [VCR::Errors::CassetteInUseError] if there is currently a cassette in use
  # @raise [ArgumentError] if you pass an invalid option
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

  # Turns on VCR, if it has previously been turned off.
  # @return [void]
  # @see #turn_off!
  # @see #turned_off
  # @see #turned_on?
  def turn_on!
    @turned_off = false
  end

  # @return whether or not VCR is turned on
  # @note Normally VCR is _always_ turned on; it will only be off if you have
  #  explicitly turned it off.
  # @see #turn_on!
  # @see #turn_off!
  # @see #turned_off
  def turned_on?
    !@turned_off
  end

  # @private
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
