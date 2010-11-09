# Aruba::Api#run in aruba 0.2.4 does not work w/ JRuby or Rubinius.
# This is the version from 0.2.2 before aruba relied upon
# BackgroundProcess (which is not jruby/rbx compatible).
require 'tempfile'

Aruba::Api.module_eval do
  def run(cmd, fail_on_error=true)
    cmd = detect_ruby(cmd)

    stderr_file = Tempfile.new('cucumber')
    stderr_file.close
    in_current_dir do
      announce_or_puts("$ cd #{Dir.pwd}") if @announce_dir
      announce_or_puts("$ #{cmd}") if @announce_cmd

      mode = RUBY_VERSION =~ /^1\.9/ ? {:external_encoding=>"UTF-8"} : 'r'
      
      IO.popen("#{cmd} 2> #{stderr_file.path}", mode) do |io|
        @last_stdout = io.read
        announce_or_puts(@last_stdout) if @announce_stdout
      end

      @last_exit_status = $?.exitstatus
    end
    @last_stderr = IO.read(stderr_file.path)

    announce_or_puts(@last_stderr) if @announce_stderr

    if(@last_exit_status != 0 && fail_on_error)
      fail("Exit status was #{@last_exit_status}. Output:\n#{combined_output}")
    end

    @last_stderr
  end
end

