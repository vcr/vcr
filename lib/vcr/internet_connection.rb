require 'ping'

module VCR
  module InternetConnection
    extend self

    EXAMPLE_HOST = "example.com"

    def available?
      @available ||= Ping.pingecho(EXAMPLE_HOST, 1, 80)
    end
  end
end
