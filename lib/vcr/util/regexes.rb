module VCR
  module Regexes
    extend self

    PROTOCOL = '\Ahttps?://'
    CREDENTIALS = '((\w+:)?\w+@)?'
    PORT = '(:\d+)?'
    THE_REST = '/?(\?.*)?\z'

    @@url_host_regexes = Hash.new do |hash, hosts|
      hash[hosts] = begin
        host_regex = hosts.map { |h| Regexp.escape(h) }.join('|')
        %r|#{PROTOCOL}#{CREDENTIALS}(#{host_regex})#{PORT}/|i
      end
    end

    def url_regex_for_hosts(hosts)
      @@url_host_regexes[hosts.sort]
    end

    @@url_path_regexes = Hash.new do |hash, path|
      %r|#{PROTOCOL}[^/]+#{Regexp.escape(path)}#{THE_REST}|i
    end

    def url_regex_for_path(path)
      @@url_path_regexes[path]
    end

    @@url_host_and_path_regexes = Hash.new do |hash, (host, path)|
      %r|#{PROTOCOL}#{CREDENTIALS}#{Regexp.escape(host)}#{PORT}#{Regexp.escape(path)}#{THE_REST}|i
    end

    def url_regex_for_host_and_path(host, path)
      @@url_host_and_path_regexes[[host, path]]
    end
  end
end
