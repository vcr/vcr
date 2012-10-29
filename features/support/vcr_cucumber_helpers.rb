require 'date'

# This file gets symlinked into the tmp/aruba directory before
# each scenario so that it is available to be required in them.
$LOAD_PATH << '../../spec' unless $LOAD_PATH.include?('../../spec')
$LOAD_PATH.unshift '../../lib'  unless $LOAD_PATH.include?('../../lib')

running_under_aruba = File.expand_path('.').include?('aruba')
if running_under_aruba
  require 'support/fixnum_extension'
  require 'vcr/util/internet_connection'

  # pretend we're always on the internet (so that we don't have an
  # internet connection dependency for our cukes)
  VCR::InternetConnection.class_eval do
    def available?; true; end
  end
end

if ENV['DATE_STRING']
  require 'timecop'
  Timecop.travel(Date.parse(ENV['DATE_STRING']))
end

def include_http_adapter_for(lib)
  require (lib =~ /faraday/ ? 'faraday' : lib)
  require 'typhoeus' if lib.include?('typhoeus') # for faraday-typhoeus
  require 'support/http_library_adapters'
  include HTTP_LIBRARY_ADAPTERS[lib]
end

def response_body_for(*args)
  get_body_string(make_http_request(*args))
end

def start_sinatra_app(options, &block)
  raise ArgumentError.new("You must pass a port") unless options[:port]

  require 'sinatra'
  require 'support/vcr_localhost_server'
  klass = Class.new(Sinatra::Base)
  klass.disable :protection
  klass.class_eval(&block)

  VCR::LocalhostServer.new(klass.new, options[:port])
end
