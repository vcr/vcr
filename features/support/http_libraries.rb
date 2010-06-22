module NetHTTPAdapter
  def get_body_string(response)
    response.body
  end

  def http_get(uri)
    Net::HTTP.get_response(uri)
  end
end

module PatronAdapter
  def get_body_string(response)
    response.body
  end

  def patron_session(uri)
    sess = Patron::Session.new
    sess.base_url = "#{uri.host}:#{uri.port}"
    sess
  end

  def http_get(uri)
    patron_session(uri).get(uri.path)
  end
end

module HTTPClientAdapter
  def get_body_string(response)
    case
      when response.is_a?(String) then response
      when response.is_a?(StringIO) then response.read
      when response.respond_to?(:body) then get_body_string(response.body)
      when response.respond_to?(:content) then get_body_string(response.content)
      else raise ArgumentError.new("Unexpected response: #{response}")
    end
  end

  def http_get(uri)
    HTTPClient.new.get(uri)
  end
end

module EmHTTPAdapter
  def get_body_string(response)
    if response.respond_to?(:body)
      response.body
    else
      response.response
    end
  end

  def http_get(uri)
    url = uri.to_s
    url << '/' if uri.path == ''

    EventMachine.run do
      http = EventMachine::HttpRequest.new(url).get
      http.callback { EventMachine.stop; return http }
    end
  end
end

World case ENV['HTTP_LIB']
  when 'patron'      then PatronAdapter
  when 'httpclient'  then HTTPClientAdapter
  when 'net/http'    then NetHTTPAdapter
  when 'em-http'     then EmHTTPAdapter
  else raise ArgumentError.new("Unexpected HTTP_LIB: #{ENV['HTTP_LIB']}")
end

