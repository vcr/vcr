require 'vcr/cassette'
require 'vcr/config'
require 'vcr/cucumber_tags'
require 'vcr/deprecations'
require 'vcr/structs'
require 'vcr/version'

require 'vcr/extensions/net_http_response'
require 'vcr/extensions/net_read_adapter'

require 'vcr/http_stubbing_adapters/base'

module VCR
  extend self

  def current_cassette
    cassettes.last
  end

  def insert_cassette(*args)
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
    yield
  ensure
    eject_cassette
  end

  def config
    yield VCR::Config
    http_stubbing_adapter.check_version!
    http_stubbing_adapter.http_connections_allowed = false
  end

  def cucumber_tags(&block)
    main_object = eval('self', block.binding)
    yield VCR::CucumberTags.new(main_object)
  end

  def http_stubbing_adapter
    @http_stubbing_adapter ||= case VCR::Config.http_stubbing_library
      when :fakeweb
        VCR::HttpStubbingAdapters::FakeWeb
      when :webmock
        VCR::HttpStubbingAdapters::WebMock
      else
        raise ArgumentError.new("The http stubbing library is not configured correctly.  You should set it to :webmock or :fakeweb.")
    end
  end

  private

  def cassettes
    @cassettes ||= []
  end
end