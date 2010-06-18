When /^I make an asynchronous HTTPClient get request to "([^\"]*)"$/ do |url|
  capture_response(url) do |uri, path|
    connection = HTTPClient.new.get_async(uri)
    connection.join
    connection.pop
  end
end
