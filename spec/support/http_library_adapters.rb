module NetHTTPAdapter
  def get_body_string(response); response.body; end

  def get_header(header_key, response)
    response.get_fields(header_key)
  end

  def make_http_request(method, url, body = {}, headers = {})
    uri = URI.parse(url)
    case method
      when :get
        Net::HTTP.get_response(uri)
      when :post
        Net::HTTP.new(uri.host, uri.port).post(uri.path, body, headers)
    end
  end
end

module PatronAdapter
  def get_body_string(response); response.body; end

  def get_header(header_key, response)
    response.headers[header_key]
  end

  def make_http_request(method, url, body = {}, headers = {})
    uri = URI.parse(url)
    sess = Patron::Session.new
    sess.base_url = "#{uri.scheme}://#{uri.host}:#{uri.port}"

    case method
      when :get
        sess.get(uri.path)
      when :post
        sess.post(uri.path, body, headers)
    end
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

  def make_http_request(method, url, body = {}, headers = {})
    case method
      when :get
        HTTPClient.new.get(url)
      when :post
        HTTPClient.new.post(url, body, headers)
    end
  end
end

module EmHTTPRequestAdapter
  def get_body_string(response)
    response.response
  end

  def get_header(header_key, response)
    response.response_header[header_key.upcase.gsub('-', '_')].split(', ')
  end

  def make_http_request(method, url, body = {}, headers = {})
    http = nil
    EventMachine.run do
      http = case method
        when :get  then EventMachine::HttpRequest.new(url).get
        when :post then EventMachine::HttpRequest.new(url).post :body => body, :head => headers
      end

      http.callback { EventMachine.stop }
    end
    http
  end
end
