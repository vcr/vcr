module MonkeyPatches
  extend self

  module RSpecMacros
    def without_monkey_patches(scope)
      before(:each) { MonkeyPatches.disable!(scope) }
      after(:each)  { MonkeyPatches.enable!(scope)  }
    end
  end

  NET_HTTP_SINGLETON = class << Net::HTTP; self; end

  MONKEY_PATCHES = [
    [Net::BufferedIO,    :initialize],
    [Net::HTTP,          :request],
    [Net::HTTP,          :connect],
    [NET_HTTP_SINGLETON, :socket_type]
  ]

  def enable!(scope)
    case scope
      when :all
        MONKEY_PATCHES.each do |mp|
          realias mp.first, mp.last, :with_monkeypatches
        end
      when :vcr
        realias Net::HTTP, :request, :with_vcr
      else raise ArgumentError.new("Unexpected scope: #{scope}")
    end
  end

  def disable!(scope)
    case scope
      when :all
        MONKEY_PATCHES.each do |mp|
          realias mp.first, mp.last, :without_monkeypatches
        end
      when :vcr
        realias Net::HTTP, :request, :without_vcr
      else raise ArgumentError.new("Unexpected scope: #{scope}")
    end
  end

  def init
    # capture the monkey patched definitions so we can realias to them in the future
    MONKEY_PATCHES.each do |mp|
      capture_method_definition(mp.first, mp.last, false)
    end
  end

  private

  def capture_method_definition(klass, method, original)
    klass.class_eval do
      monkeypatch_methods = [
        :with_vcr,     :without_vcr,
        :with_fakeweb, :without_fakeweb,
        :with_webmock, :without_webmock
      ].select do |m|
        method_defined?(:"#{method}_#{m}")
      end

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
  MONKEY_PATCHES.each do |mp|
    capture_method_definition(mp.first, mp.last, true)
  end

  def realias(klass, method, alias_extension)
    klass.class_eval { alias_method method, :"#{method}_#{alias_extension}" }
  end
end

# Require all the HTTP libraries--these must be required before WebMock
# for WebMock to work with them.
require 'httpclient'

if RUBY_INTERPRETER == :mri
  require 'patron'
  require 'em-http-request'
  require 'curb'
  require 'typhoeus'
end

# The FakeWeb adapter must be required after WebMock's so
# that VCR's Net::HTTP monkey patch is loaded last.
# This allows us to disable it (i.e. by realiasing to
# the version of Net::HTTP's methods before it was loaded)
require 'vcr/http_stubbing_adapters/webmock'
require 'vcr/http_stubbing_adapters/fakeweb'

# All Net::HTTP monkey patches have now been loaded, so capture the
# appropriate method definitions so we can disable them later.
MonkeyPatches.init
