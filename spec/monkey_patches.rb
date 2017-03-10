module MonkeyPatches
  extend self

  def enable!(scope)
    case scope
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
      else raise ArgumentError.new("Unexpected scope: #{scope}")
    end
  end

  def disable_all!
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
end

# Require all the HTTP libraries--these must be required before WebMock
# for WebMock to work with them.
require 'httpclient'

if RUBY_INTERPRETER == :mri
  require 'typhoeus'
  begin
    require 'patron'
    require 'em-http-request'
    require 'curb'
  rescue LoadError
    # these are not always available, depending on the Gemfile used
    warn $!.message
  end
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

require 'vcr/library_hooks/webmock'
$original_webmock_callbacks = ::WebMock::CallbackRegistry.callbacks

require 'vcr/library_hooks/excon'
$excon_after_loaded_hook = VCR.configuration.hooks[:after_library_hooks_loaded].last

# disable all by default; we'll enable specific ones when we need them
MonkeyPatches.disable_all!

RSpec.configure do |config|
  [:webmock, :typhoeus, :typhoeus_0_4, :excon].each do |scope|
    config.before(:all, :with_monkey_patches => scope) { MonkeyPatches.enable!(scope) }
    config.after(:all,  :with_monkey_patches => scope) { MonkeyPatches.disable_all!   }
  end
end

