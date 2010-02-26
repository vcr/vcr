require 'vcr/cassette'
require 'vcr/config'
require 'vcr/cucumber_tags'
require 'vcr/recorded_response'

require 'vcr/extensions/fake_web'
require 'vcr/extensions/net_http'
require 'vcr/extensions/net_read_adapter'

module VCR
  extend self

  def current_cassette
    cassettes.last
  end

  def create_cassette!(*args)
    cassette = Cassette.new(*args)
    cassettes.push(cassette)
    cassette
  end

  def destroy_cassette!
    cassette = cassettes.pop
    cassette.destroy! if cassette
    cassette
  end

  def with_cassette(*args)
    create_cassette!(*args)
    yield
  ensure
    destroy_cassette!
  end

  def config
    yield VCR::Config
  end

  def cucumber_tags(&block)
    main_object = eval('self', block.binding)
    yield VCR::CucumberTags.new(main_object)
  end

  private

  def cassettes
    @cassettes ||= []
  end
end