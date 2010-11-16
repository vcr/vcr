# This file gets symlinked into the tmp/aruba directory before
# each scenario so that it is available to be required in them.
$LOAD_PATH.unshift '../../spec' unless $LOAD_PATH.include?('../../spec')
$LOAD_PATH.unshift '../../lib'  unless $LOAD_PATH.include?('../../lib')

RUNNING_UNDER_ARUBA = File.dirname(__FILE__) == '.' || File.dirname(__FILE__) =~ /aruba/

require 'support/fixnum_extension' if RUNNING_UNDER_ARUBA

if ENV['DAYS_PASSED']
  require 'timecop'
  Timecop.travel(Time.now + ENV['DAYS_PASSED'].to_i.days)
end

def include_http_adapter_for(lib)
  require 'support/http_library_adapters'
  require lib
  include HTTP_LIBRARY_ADAPTERS[lib]
end

def get_response(*args)
  get_body_string(make_http_request(*args))
end

def start_sinatra_app(options, &block)
  raise ArgumentError.new("You must pass a port") unless options[:port]

  require 'sinatra'
  require 'support/vcr_localhost_server'
  klass = Class.new(Sinatra::Base)
  klass.class_eval(&block)

  VCR::LocalhostServer.new(klass.new, options[:port])
end
