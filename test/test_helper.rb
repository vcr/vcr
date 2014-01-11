require 'rubygems'

using_git = File.exist?(File.expand_path('../../.git/', __FILE__))
require 'bundler/setup' if using_git

require "minitest"
require "minitest/spec"
require "minitest/autorun"
require "vcr"
require "pry"
require "pry-debugger"

module VCR
  SPEC_ROOT = File.dirname(File.expand_path('.', __FILE__))

  def reset!(hook = :fakeweb)
    instance_variables.each do |ivar|
      instance_variable_set(ivar, nil)
    end
    configuration.hook_into hook if hook
  end
end


