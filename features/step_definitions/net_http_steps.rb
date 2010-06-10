module NetHTTPHelpers
  def perform_net_http_get_with_returning_block(uri, path)
    Net::HTTP.new(uri.host, uri.port).request(Net::HTTP::Get.new(path, {})) do |response|
      return response
    end
  end
end
World(NetHTTPHelpers)

When /^I make an asynchronous HTTP get request to "([^\"]*)"$/ do |url|
  capture_response(url) do |uri, path|
    result = Net::HTTP.new(uri.host, uri.port).request_get(path) { |r| r.read_body { } }
    result.body.should be_a(Net::ReadAdapter)
    result
  end
end

When /^I make a replayed asynchronous HTTP get request to "([^\"]*)"$/ do |url|
  capture_response(url) do |uri, path|
    result_body = ''
    result = Net::HTTP.new(uri.host, uri.port).request_get(path) { |r| r.read_body { |fragment| result_body << fragment } }
    result.body.should == result_body
    result
  end
end

When /^I make a recursive HTTP post request to "([^\"]*)"$/ do |url|
  capture_response(url) do |uri, path|
    Net::HTTP.new(uri.host, uri.port).post(path, nil)
  end
end

When /^I make a returning block HTTP get request to "([^\"]*)"$/ do |url|
  capture_response(url) do |uri, path|
    perform_net_http_get_with_returning_block(uri, path)
  end
end