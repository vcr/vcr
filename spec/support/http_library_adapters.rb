HTTP_LIBRARY_ADAPTERS = {}

HTTP_LIBRARY_ADAPTERS['net/http'] = Module.new do
  def self.http_library_name; 'Net::HTTP'; end

  def get_body_string(response); response.body; end

  def get_header(header_key, response)
    response.get_fields(header_key)
  end

  def make_http_request(method, url, body = nil, headers = {})
    uri = URI.parse(url)
    Net::HTTP.new(uri.host, uri.port).send_request(method.to_s.upcase, uri.request_uri, body, headers)
  end
end

HTTP_LIBRARY_ADAPTERS['patron'] = Module.new do
  def self.http_library_name; 'Patron'; end

  def get_body_string(response); response.body; end

  def get_header(header_key, response)
    response.headers[header_key]
  end

  def make_http_request(method, url, body = nil, headers = {})
    Patron::Session.new.request(method, url, headers, :data => body || '')
  end
end

HTTP_LIBRARY_ADAPTERS['httpclient'] = Module.new do
  def self.http_library_name; 'HTTP Client'; end

  def get_body_string(response)
    string = response.body.content
    string.respond_to?(:read) ? string.read : string
  end

  def get_header(header_key, response)
    response.header[header_key]
  end

  def make_http_request(method, url, body = nil, headers = {})
    HTTPClient.new.request(method, url, nil, body, headers)
  end
end

HTTP_LIBRARY_ADAPTERS['em-http-request'] = Module.new do
  def self.http_library_name; 'EM HTTP Request'; end

  def get_body_string(response)
    response.response
  end

  def get_header(header_key, response)
    response.response_header[header_key.upcase.gsub('-', '_')].split(', ')
  end

  def make_http_request(method, url, body = nil, headers = {})
    http = nil
    EventMachine.run do
      http = EventMachine::HttpRequest.new(url).send(method, :body => body, :head => headers)
      http.callback { EventMachine.stop }
    end
    http
  end
end

HTTP_LIBRARY_ADAPTERS['curb'] = Module.new do
  def self.http_library_name; "Curb"; end

  def get_body_string(response)
    response.body_str
  end

  def get_header(header_key, response)
    headers = response.header_str.split("\r\n")[1..-1]
    headers.each do |h|
      if h =~ /^#{Regexp.escape(header_key)}: (.*)$/
        return $1.split(', ')
      end
    end
  end

  def make_http_request(method, url, body = nil, headers = {})
    Curl::Easy.new(url) do |c|
      c.headers = headers

      if [:post, :put].include?(method)
        c.send("http_#{method}", body)
      else
        c.send("http_#{method}")
      end
    end
  end
end

HTTP_LIBRARY_ADAPTERS['typhoeus'] = Module.new do
  def self.http_library_name; "Typhoeus"; end

  def get_body_string(response)
    response.body
  end

  def get_header(header_key, response)
    response.headers_hash[header_key]
  end

  def make_http_request(method, url, body = nil, headers = {})
    Typhoeus::Request.send(method, url, :body => body, :headers => headers)
  end
end

%w[ net_http typhoeus patron ].each do |_faraday_adapter|
  HTTP_LIBRARY_ADAPTERS["faraday-#{_faraday_adapter}"] = Module.new do
    class << self; self; end.class_eval do
      define_method(:http_library_name) do
        "Faraday (#{_faraday_adapter})"
      end
    end

    define_method(:faraday_adapter) { _faraday_adapter.to_sym }

    def get_body_string(response)
      response.body
    end

    def get_header(header_key, response)
      response.headers[header_key]
    end

    def make_http_request(method, url, body = nil, headers = {})
      url_root, url_rest = split_url(url)

      faraday_connection(url_root).send(method) do |req|
        req.url url_rest
        headers.each { |k, v| req[k] = v }
        req.body = body if body
      end
    end

    def split_url(url)
      uri = URI.parse(url)
      url_root = "#{uri.scheme}://#{uri.host}:#{uri.port}"
      rest = url.sub(url_root, '')

      [url_root, rest]
    end

    def faraday_connection(url_root)
      Faraday::Connection.new(:url => url_root) do |builder|
        builder.use VCR::Middleware::Faraday do |cassette|
          cassette.name    'faraday_example'

          if respond_to?(:match_requests_on)
            cassette.options :match_requests_on => match_requests_on
          end

          if respond_to?(:record_mode)
            cassette.options :record => record_mode
          end
        end

        builder.adapter faraday_adapter
      end
    end
  end
end
