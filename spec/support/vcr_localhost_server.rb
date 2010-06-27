require 'capybara'
require 'capybara/wait_until'

# This uses a separate process rather than a separate thread to run the server.
# Patron always times out when this is running in a thread in the same process.
#
# However, jruby doesn't support forking, and patron doesn't work on jruby...
# so we just leave Capybara::Server's definition of #boot.
class VCR::LocalhostServer < Capybara::Server

  def boot
    return self unless @app
    find_available_port
    Capybara.log "application has already booted" and return self if responsive?
    Capybara.log "booting Rack applicartion on port #{port}"

    pid = Process.fork do
      trap(:INT) { Rack::Handler::WEBrick.shutdown }
      Rack::Handler::WEBrick.run(Identify.new(@app), :Port => port, :AccessLog => [])
      exit # manually exit; otherwise this sub-process will re-run the specs that haven't run yet.
    end
    Capybara.log "checking if application has booted"

    Capybara::WaitUntil.timeout(10) do
      if responsive?
        Capybara.log("application has booted")
        true
      else
        sleep 0.5
        false
      end
    end

    at_exit do
      Process.kill('INT', pid)
      begin
        Process.wait(pid)
      rescue Errno::ECHILD
        # ignore this error...I think it means the child process has already exited.
      end
    end

    self
  rescue Timeout::Error
    Capybara.log "Rack application timed out during boot"
    exit
  end unless RUBY_PLATFORM =~ /java/

  STATIC_SERVERS = Hash.new do |h, k|
    h[k] = server = new(lambda { |env| [200, {}, StringIO.new(k)] })
    server.boot
  end
end
