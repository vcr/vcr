require 'rubygems' if RUBY_VERSION =~ /^1\.8/
require 'bundler/setup'
require 'rspec/core'
require 'rspec/expectations'
require 'tempfile'

stderr_file = Tempfile.new("vcr.stderr")
current_dir = Dir.pwd

RSpec.configure do |config|
  config.before(:suite) do
    $stderr.reopen(stderr_file.path)
    $VERBOSE = true
  end

  config.after(:suite) do
    stderr_file.rewind
    lines = stderr_file.read.split("\n").uniq
    stderr_file.close!

    $stderr.reopen(STDERR)

    vcr_warnings, other_warnings = lines.partition { |line| line.include?(current_dir) }

    # After upgrading to curb 0.8.1, I started to get a circular require
    # warning from spec_helper and monkey_patches.rb even though there doesn't
    # appear to be a circular require going on...
    vcr_warnings.reject! do |line|
      line.include?("#{current_dir}/spec/spec_helper.rb") ||
      line.include?("#{current_dir}/spec/monkey_patches.rb")
    end

    # For some weird reason, JRuby is giving me some warnings about
    # `@proxy` not being initialized, and putting a vcr file/line number
    # in the warning, but it's really happening in excon.
    if RUBY_PLATFORM == 'java'
      vcr_warnings.reject! do |line|
        line.include?('@proxy not initialized') && line.include?('excon')
      end
    end

    # For some reason, I get a strange warning on 1.9.2 on Travis-CI but
    # I can't repro locally:
    # from /home/travis/builds/myronmarston/vcr/spec/monkey_pnet/http:
    # warning: Content-Type did not set; using application/x-www-form-urlencoded
    if RUBY_VERSION == '1.9.2' && ENV['CI']
      vcr_warnings.reject! do |line|
        line.include?('monkey_pnet')
      end
    end

    if vcr_warnings.any?
      puts
      puts "-" * 30 + " VCR Warnings: " + "-" * 30
      puts
      puts vcr_warnings.join("\n")
      puts
      puts "-" * 75
      puts
    end

    if other_warnings.any?
      File.open('tmp/warnings.txt', 'w') { |f| f.write(other_warnings.join("\n")) }
      puts
      puts "Non-VCR warnings written to tmp/warnings.txt"
      puts
    end

    # fail the build...
    raise "Failing build due to VCR warnings" if vcr_warnings.any?
  end
end

