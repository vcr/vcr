require 'rubygems'
require 'bundler'
Bundler.setup

require 'aruba'

Before do
  this_dir = File.dirname(__FILE__)
  in_current_dir do
    FileUtils.ln_s File.join(this_dir, 'vcr_cucumber_helpers.rb'), 'vcr_cucumber_helpers.rb'
  end
end
