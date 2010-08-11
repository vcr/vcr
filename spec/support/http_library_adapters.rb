module NetHTTPAdapter
  def get_body_string(response); response.body; end

  def get_header(header_key, response)
    response.get_fields(header_key)
  end

  def make_http_request(method, url, body = '', headers = {})
    uri = URI.parse(url)
    Net::HTTP.new(uri.host, uri.port).send_request(method.to_s.upcase, uri.path, body, headers)
  end
end

module PatronAdapter
  def get_body_string(response); response.body; end

  def get_header(header_key, response)
    response.headers[header_key]
  end

  def make_http_request(method, url, body = '', headers = {})
    Patron::Session.new.request(method, url, headers, :data => body)
  end
end

module HTTPClientAdapter
  def get_body_string(response)
    string = response.body.content
    string.respond_to?(:read) ? string.read : string
  end

  def get_header(header_key, response)
    response.header[header_key]
  end

  def make_http_request(method, url, body = '', headers = {})
    HTTPClient.new.request(method, url, nil, body, headers)
  end
end

module EmHTTPRequestAdapter
  def get_body_string(response)
    response.response
  end

  def get_header(header_key, response)
    response.response_header[header_key.upcase.gsub('-', '_')].split(', ')
  end

  def make_http_request(method, url, body = '', headers = {})
    http = nil
    EventMachine.run do
      http = EventMachine::HttpRequest.new(url).send(method, :body => body, :head => headers)
      http.callback { EventMachine.stop }
    end
    http
  end
end
