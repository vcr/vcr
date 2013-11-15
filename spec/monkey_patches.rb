require 'typhoeus'

module MonkeyPatches
  extend self

  NET_HTTP_SINGLETON = class << Net::HTTP; self; end

  NET_HTTP_MONKEY_PATCHES = [
    [Net::BufferedIO,    :initialize],
    [Net::HTTP,          :request],
    [Net::HTTP,          :connect],
    [NET_HTTP_SINGLETON, :socket_type]
  ]

  ALL_MONKEY_PATCHES = NET_HTTP_MONKEY_PATCHES.dup

  def enable!(scope)
    case scope
      when :fakeweb
        realias_net_http :with_fakeweb
        enable!(:vcr) # fakeweb hook relies upon VCR's Net::HTTP monkey patch
      when :webmock
        ::WebMock.reset!
        ::WebMock::HttpLibAdapters::NetHttpAdapter.enable!
        ::WebMock::HttpLibAdapters::TyphoeusAdapter.enable! if defined?(::Typhoeus)
        ::WebMock::HttpLibAdapters::ExconAdapter.enable! if defined?(::Excon)
        $original_webmock_callbacks.each do |cb|
          ::WebMock::CallbackRegistry.add_callback(cb[:options], cb[:block])
        end
      when :typhoeus
        $original_typhoeus_global_hooks.each do |hook|
          ::Typhoeus.on_complete << hook
        end
        ::Typhoeus.before.clear
        $original_typhoeus_before_hooks.each do |hook|
          ::Typhoeus.before << hook
        end
      when :typhoeus_0_4
        ::Typhoeus::Hydra.global_hooks = $original_typhoeus_global_hooks
        ::Typhoeus::Hydra.stub_finders.clear
        $original_typhoeus_stub_finders.each do |finder|
          ::Typhoeus::Hydra.stub_finders << finder
        end
      when :excon
        VCR::LibraryHooks::Excon.configure_middleware
      when :vcr
        realias Net::HTTP, :request, :with_vcr
      else raise ArgumentError.new("Unexpected scope: #{scope}")
    end
  end

  def disable_all!
    realias_all :without_monkeypatches

    if defined?(::WebMock::HttpLibAdapters)
      ::WebMock::HttpLibAdapters::NetHttpAdapter.disable!
      ::WebMock::HttpLibAdapters::TyphoeusAdapter.disable! if defined?(::Typhoeus)
      ::WebMock::HttpLibAdapters::ExconAdapter.disable! if defined?(::Excon)
      ::WebMock::CallbackRegistry.reset
      ::WebMock::StubRegistry.instance.request_stubs = []
    end

    if defined?(::Typhoeus.before)
      ::Typhoeus.on_complete.clear
      ::Typhoeus.before.clear
    elsif defined?(::Typhoeus::Hydra)
      ::Typhoeus::Hydra.clear_global_hooks
      ::Typhoeus::Hydra.stub_finders.clear
    end

    if defined?(::Excon)
      ::Excon.defaults[:middlewares].delete(VCR::Middleware::Excon::Request)
      ::Excon.defaults[:middlewares].delete(VCR::Middleware::Excon::Response)
    end
  end

  def init
    # capture the monkey patched definitions so we can realias to them in the future
    ALL_MONKEY_PATCHES.each do |mp|
      capture_method_definition(mp.first, mp.last, false)
    end
  end

  private

  def capture_method_definition(klass, method, original)
    klass.class_eval do
      monkeypatch_methods = [:vcr, :fakeweb].select { |m| method_defined?(:"#{method}_with_#{m}") }

      if original
        if monkeypatch_methods.size > 0
          raise "The following monkeypatch methods have already been defined #{method}: #{monkey_patch_methods.inspect}"
        end
        alias_name = :"#{method}_without_monkeypatches"
      else
        if monkeypatch_methods.size == 0
          raise "No monkey patch methods have been defined for #{method}"
        end
        alias_name = :"#{method}_with_monkeypatches"
      end

      alias_method alias_name, method
    end
  end

  # capture the original method definitions before the monkey patches have been defined
  # so we can realias to the originals in the future
  ALL_MONKEY_PATCHES.each do |mp|
    capture_method_definition(mp.first, mp.last, true)
  end

  def realias(klass, method, alias_extension)
    klass.class_eval do
      old_verbose, $VERBOSE = $VERBOSE, nil
      alias_method method, :"#{method}_#{alias_extension}"
      $VERBOSE = old_verbose
    end
  end

  def realias_all(alias_extension)
    ALL_MONKEY_PATCHES.each do |mp|
      realias mp.first, mp.last, alias_extension
    end
  end

  def realias_net_http(alias_extension)
    NET_HTTP_MONKEY_PATCHES.each do |mp|
      realias mp.first, mp.last, alias_extension
    end
  end
end

# Require all the HTTP libraries--these must be required before WebMock
# for WebMock to work with them.
require 'httpclient'

unless RUBY_INTERPRETER == :jruby
  require 'patron'
  require 'em-http-request'
  require 'curb'
end

if defined?(::Typhoeus.before)
  require 'vcr/library_hooks/typhoeus'
  $typhoeus_after_loaded_hook = VCR.configuration.hooks[:after_library_hooks_loaded].last
  $original_typhoeus_global_hooks = Typhoeus.on_complete.dup
  $original_typhoeus_before_hooks = Typhoeus.before.dup
elsif defined?(::Typhoeus::Hydra.global_hooks)
  require 'vcr/library_hooks/typhoeus'
  $typhoeus_0_4_after_loaded_hook = VCR.configuration.hooks[:after_library_hooks_loaded].first
  $typhoeus_after_loaded_hook = VCR.configuration.hooks[:after_library_hooks_loaded].last
  $original_typhoeus_global_hooks = Typhoeus::Hydra.global_hooks.dup
  $original_typhoeus_stub_finders = Typhoeus::Hydra.stub_finders.dup
end

require 'vcr/library_hooks/fakeweb'
$fakeweb_after_loaded_hook = VCR.configuration.hooks[:after_library_hooks_loaded].last

# All Net::HTTP monkey patches have now been loaded, so capture the
# appropriate method definitions so we can disable them later.
MonkeyPatches.init

# Disable FakeWeb/VCR Net::HTTP patches before WebMock
# subclasses Net::HTTP and inherits them...
MonkeyPatches.disable_all!

require 'vcr/library_hooks/webmock'
$original_webmock_callbacks = ::WebMock::CallbackRegistry.callbacks

require 'vcr/library_hooks/excon'
$excon_after_loaded_hook = VCR.configuration.hooks[:after_library_hooks_loaded].last

# disable all by default; we'll enable specific ones when we need them
MonkeyPatches.disable_all!

RSpec.configure do |config|
  [:fakeweb, :webmock, :vcr, :typhoeus, :typhoeus_0_4, :excon].each do |scope|
    config.before(:all, :with_monkey_patches => scope) { MonkeyPatches.enable!(scope) }
    config.after(:all,  :with_monkey_patches => scope) { MonkeyPatches.disable_all!   }
  end
end

