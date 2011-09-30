require 'uri'
require 'set'

module VCR
  class RequestIgnorer
    LOCALHOST_ALIASES = %w( localhost 127.0.0.1 0.0.0.0 )

    def ignore_localhost=(value)
      if value
        ignore_hosts(*LOCALHOST_ALIASES)
      else
        ignored_hosts.reject! { |h| LOCALHOST_ALIASES.include?(h) }
      end
    end

    def ignore_hosts(*hosts)
      ignored_hosts.merge(hosts)
    end

    def ignore?(request)
      ignored_hosts.include?(URI(request.uri).host)
    end

  private

    def ignored_hosts
      @ignored_hosts ||= Set.new
    end
  end
end

