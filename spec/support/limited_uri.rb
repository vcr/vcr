require 'forwardable'

class LimitedURI
  extend Forwardable

  def_delegators :@uri, :scheme, :host, :host=, :port, :port=, :path, :query, :query=, :to_s

  def initialize(uri)
    @uri = uri
  end

  def ==(other)
    to_s == other.to_s
  end

  def self.parse(uri)
    uri = if uri.is_a? LimitedURI
            uri
          elsif uri.is_a? URI
            new(uri)
          elsif uri.is_a? String
            new(URI.parse(uri))
          end

    raise URI::InvalidURIError if uri.nil?

    uri.host = uri.host.chomp('.')
    uri
  end
end
