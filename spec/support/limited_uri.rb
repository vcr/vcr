class LimitedURI
  extend Forwardable

  def_delegators :@uri, :scheme, :host, :port, :port=, :path, :query, :query=, :to_s

  def initialize(uri)
    @uri = uri
  end

  def ==(other)
    to_s == other.to_s
  end

  def self.parse(uri)
    return uri if uri.is_a? LimitedURI
    return new(uri) if uri.is_a? URI
    return new(URI.parse(uri)) if uri.is_a? String

    raise URI::InvalidURIError
  end
end
