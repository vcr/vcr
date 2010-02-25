require 'vcr/config'
require 'vcr/fake_web_extensions'
require 'vcr/net_http_extensions'
require 'vcr/recorded_response'
require 'vcr/sandbox'

module VCR
  extend self

  def current_sandbox
    sandboxes.last
  end

  def create_sandbox!(*args)
    sandbox = Sandbox.new(*args)
    sandboxes.push(sandbox)
    sandbox
  end

  def destroy_sandbox!
    sandbox = sandboxes.pop
    sandbox.destroy! if sandbox
    sandbox
  end

  def with_sandbox(*args)
    create_sandbox!(*args)
    yield
  ensure
    destroy_sandbox!
  end

  def config
    yield VCR::Config
  end

  private

  def sandboxes
    @sandboxes ||= []
  end
end