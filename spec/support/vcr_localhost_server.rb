require 'capybara'
require 'capybara/wait_until'

# This uses a separate process rather than a separate thread to run the server.
# Patron always times out when this is running in a thread in the same process.
class VCR::LocalhostServer < Capybara::Server
  def boot
    return self unless @app
    find_available_port
    Capybara.log "application has already booted" and return self if responsive?
    Capybara.log "booting Rack applicartion on port #{port}"

    Process.fork do
      handler.run(Identify.new(@app), :Port => port, :AccessLog => [])
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
    self
  rescue Timeout::Error
    Capybara.log "Rack application timed out during boot"
    exit
  end

  STATIC_SERVERS = Hash.new do |h, k|
    h[k] = server = new(lambda { |env| [200, {}, StringIO.new(k)] })
    server.boot
  end
end
