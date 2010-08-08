module NetHTTPAdapter
  def get_body_string(response); response.body; end

  def get_header(header_key, response)
    response.get_fields(header_key)
  end

  def make_http_request(method, url, body = {})
    case method
      when :get
        Net::HTTP.get_response(URI.parse(url))
      when :post
        Net::HTTP.post_form(URI.parse(url), body)
    end
  end
end

module PatronAdapter
  def get_body_string(response); response.body; end

  def get_header(header_key, response)
    response.headers[header_key]
  end

  def make_http_request(method, url, body = {})
    uri = URI.parse(url)
    sess = Patron::Session.new
    sess.base_url = "#{uri.scheme}://#{uri.host}:#{uri.port}"

    case method
      when :get
        sess.get(uri.path)
      when :post
        sess.post(uri.path, body)
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

  def make_http_request(method, url, body = {})
    case method
      when :get
        HTTPClient.new.get(url)
      when :post
        HTTPClient.new.post(url, body)
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

  def make_http_request(method, url, body = {})
    http = nil
    EventMachine.run do
      http = case method
        when :get  then EventMachine::HttpRequest.new(url).get
        when :post then EventMachine::HttpRequest.new(url).post :body => body
      end

      http.callback { EventMachine.stop }
    end
    http
  end
end
