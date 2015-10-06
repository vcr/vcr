require "rubygems"
require "vcr"
require "support/fixnum_extension"

module Gem
  def self.win_platform?() false end
end unless defined?(Gem)

# pretend we're always on the internet (so that we don't have an
# internet connection dependency for our cukes)
VCR::InternetConnection.class_eval do
  def available?; true; end
end

if ENV['DATE_STRING']
  require 'timecop'
  Timecop.travel(Date.parse(ENV['DATE_STRING']))
end

def include_http_adapter_for(lib)
  require((lib =~ /faraday/) ? 'faraday' : lib)
  require 'typhoeus' if lib.include?('typhoeus') # for faraday-typhoeus
  require 'support/http_library_adapters'
  include HTTP_LIBRARY_ADAPTERS[lib]
end

def response_body_for(*args)
  get_body_string(make_http_request(*args))
end

def start_sinatra_app(&block)
  require 'sinatra/base'
  require 'support/vcr_localhost_server'
  klass = Class.new(Sinatra::Base)
  klass.disable :protection
  klass.class_eval(&block)

  VCR::LocalhostServer.new(klass.new)
end
