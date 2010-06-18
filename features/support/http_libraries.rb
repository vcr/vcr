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
    sess.base_url = uri.host
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

World case ENV['HTTP_LIB']
  when 'patron'      then PatronAdapter
  when 'httpclient'  then HTTPClientAdapter
  when 'net/http'    then NetHTTPAdapter
  else raise ArgumentError.new("Unexpected HTTP_LIB: #{ENV['HTTP_LIB']}")
end

