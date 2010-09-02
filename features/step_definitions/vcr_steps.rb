require 'tmpdir'

RSpec::Matchers.define :have_expected_response do |regex_str, request_attributes|
  def matched_responses(responses, request_attributes)
    url, request_body, request_headers = request_attributes[:url], request_attributes[:request_body], request_attributes[:request_headers]

    selector = case url
      when String then lambda { |r| URI.parse(r.uri) == URI.parse(url) }
      when Regexp then lambda { |r| r.uri == url }
      else raise ArgumentError.new("Unexpected url: #{url.class.to_s}: #{url.inspect}")
    end

    matched = responses.select(&selector)

    if request_body
      matched = matched.select { |r| r.request.body == request_body }
    end

    (request_headers || {}).each do |r_key, r_val|
      matched = matched.select do |r|
        r.request.headers.any? { |k, v| k.downcase == r_key.downcase && v == [r_val] }
      end
    end

    matched
  end

  match do |responses|
    regex = /#{regex_str}/i
    matched_responses(responses, request_attributes).detect { |r| r.response.body =~ regex }
  end

  failure_message_for_should do |responses|
    url = request_attributes[:url]
    responses = matched_responses(responses, request_attributes)
    response_bodies = responses.map { |r| r.response.body }
    "expected a response for #{url.inspect} to match /#{regex_str}/.  Responses for #{url.inspect}:\n\n #{response_bodies.join("\n\n")}"
  end
end

RSpec::Matchers.define :be_tagged_with do |tag|
  match do |scenario|
    scenario.source_tag_names.include?(tag)
  end

  failure_message_for_should do |scenario|
    "expected scenario to be tagged with #{tag}.  Tags: #{scenario.source_tag_names.inspect}"
  end
end

RSpec::Matchers.define :have_normalized_headers do
  match do |object|
    headers = object.headers
    headers.is_a?(Hash) &&
      headers.keys.map { |k| k.downcase } == headers.keys &&
      headers.values.all? { |val| val.is_a?(Array) }
  end

  failure_message_for_should do |object|
    "expected headers to be normalized to have lower cased keys and arrays as values.  Actual headers: #{object.headers.inspect}"
  end
end

module VCRHelpers
  def static_rack_server(response_string)
    orig_ignore_localhost = VCR.http_stubbing_adapter.ignore_localhost?
    VCR.http_stubbing_adapter.ignore_localhost = true

    begin
      VCR::LocalhostServer::STATIC_SERVERS[response_string]
    ensure
      VCR.http_stubbing_adapter.ignore_localhost = orig_ignore_localhost
    end
  end

  def recorded_interactions_for(cassette_name)
    yaml_file = File.join(VCR::Config.cassette_library_dir, "#{cassette_name}.yml")
    yaml = File.open(yaml_file, 'r') { |f| f.read }
    interactions = YAML.load(yaml)
  end

  def capture_response(url)
    @http_requests ||= Hash.new([])
    uri = URI.parse(url)
    path = uri.path.to_s == '' ? '/' : uri.path
    begin
      result = yield uri, path
    rescue => e
      result = e
    end
    @http_requests[url] += [result]
  end

end
World(VCRHelpers)

Given /^we do not have a "([^\"]*)" cassette$/ do |cassette_name|
  fixture_file = File.join(VCR::Config.cassette_library_dir, "#{cassette_name}.yml")
  File.exist?(fixture_file).should be_false
end

Given /^we have a "([^\"]*)" library file with (a|no) previously recorded response for "([^\"]*)"$/ do |file_name, a_or_no, url|
  fixture_file = File.join(VCR::Config.cassette_library_dir, "#{file_name}.yml")
  File.exist?(fixture_file).should be_true
  responses = File.open(fixture_file, 'r') { |f| YAML.load(f.read) }
  should_method = a_or_no == 'a' ? :should : :should_not
  responses.map{ |r| URI.parse(r.uri) }.send(should_method, include(URI.parse(url)))
end

Given /^the "([^\"]*)" library file has a response for "([^\"]*)" that matches \/(.+)\/$/ do |cassette_name, url, regex_str|
  Given %{we have a "#{cassette_name}" library file with a previously recorded response for "#{url}"}
  Then %{the "#{cassette_name}" library file should have a response for "#{url}" that matches /#{regex_str}/}
end

Given /^the "([^\"]*)" library file has a response for \/(\S+)\/ that matches \/(.+)\/$/ do |cassette_name, url_regex, body_regex|
  recorded_interactions_for(cassette_name).should have_expected_response(body_regex, :url => /#{url_regex}/)
end

Given /^the "([^"]*)" library file has a response for "([^"]*)" with the request body "([^"]*)" that matches \/(.+)\/$/ do |cassette_name, url, request_body, response_regex|
  recorded_interactions_for(cassette_name).should have_expected_response(response_regex, :url => url, :request_body => request_body)
end

Given /^the "([^"]*)" library file has a response for "([^"]*)" with the request header "([^"]*)=([^"]*)" that matches \/(.+)\/$/ do |cassette_name, url, header_key, header_value, response_regex|
  recorded_interactions_for(cassette_name).should have_expected_response(response_regex, :url => url, :request_headers => { header_key => header_value })
end

Given /^this scenario is tagged with the vcr cassette tag: "([^\"]+)"$/ do |tag|
  VCR.current_cucumber_scenario.should be_tagged_with(tag)
  VCR::CucumberTags.tags.should include(tag)
end

Given /^the previous scenario was tagged with the vcr cassette tag: "([^\"]*)"$/ do |tag|
  last_scenario = VCR.completed_cucumber_scenarios.last
  last_scenario.should_not be_nil
  last_scenario.should be_tagged_with(tag)
  VCR::CucumberTags.tags.should include(tag)
end

When /^I make (?:an )?HTTP get request to "([^\"]*)"$/ do |url|
  capture_response(url) do |uri, path|
    make_http_request(:get, url)
  end
end

When /^I make an HTTP post request to "([^"]*)" with request body "([^"]*)"$/ do |url, request_body|
  capture_response(url) do |uri, path|
    make_http_request(:post, url, request_body)
  end
end

When /^I make an HTTP post request to "([^"]*)" with request header "([^"]*)=([^"]*)"$/ do |url, header_key, header_val|
  capture_response(url) do |uri, path|
    make_http_request(:post, url, '', { header_key => header_val })
  end
end

When /^I make (.*) requests? to "([^\"]*)"(?: and "([^\"]*)")? within the "([^\"]*)" cassette(?: using cassette options: (.*))?$/ do |http_request_type, url1, url2, cassette_name, options|
  options = options.to_s == '' ? { :record => :new_episodes } : eval(options)
  urls = [url1, url2].select { |u| u.to_s.size > 0 }
  VCR.use_cassette(cassette_name, options) do
    urls.each do |url|
      When %{I make #{http_request_type} request to "#{url}"}
    end
  end
end

When /^I make an HTTP post request to "([^"]*)" with request body "([^"]*)" within the "([^"]*)" cassette(?: using cassette options: (.*))?$/ do |url, request_body, cassette_name, options|
  options = options.to_s == '' ? { :record => :new_episodes } : eval(options)
  VCR.use_cassette(cassette_name, options) do
    When %{I make an HTTP post request to "#{url}" with request body "#{request_body}"}
  end
end

When /^I make an HTTP post request to "([^"]*)" with request header "([^"]*)=([^"]*)" within the "([^"]*)" cassette(?: using cassette options: (.*))?$/ do |url, header_key, header_value, cassette_name, options|
  options = options.to_s == '' ? { :record => :new_episodes } : eval(options)
  VCR.use_cassette(cassette_name, options) do
    When %{I make an HTTP post request to "#{url}" with request header "#{header_key}=#{header_value}"}
  end
end

Then /^the "([^\"]*)" library file should have a response for "([^\"]*)" that matches \/(.+)\/$/ do |cassette_name, url, regex_str|
  interactions = recorded_interactions_for(cassette_name)
  interactions.should have_expected_response(regex_str, :url => url)
end

Then /^the "([^\"]*)" library file should have exactly (\d+) response$/ do |cassette_name, response_count|
  interactions = recorded_interactions_for(cassette_name)
  interactions.should have(response_count.to_i).responses
end

Then /^the "([^"]*)" library file should have normalized headers for all recorded interactions$/ do |cassette_name|
  interactions = recorded_interactions_for(cassette_name)
  interactions.each do |i|
    i.request.should have_normalized_headers
    i.response.should have_normalized_headers
  end
end

Then /^I can test the scenario cassette's recorded responses in the next scenario, after the cassette has been ejected$/ do
  # do nothing...
end

Then /^the HTTP get request to "([^\"]*)" should result in an error that mentions VCR$/ do |url|
  result = @http_requests[url][0]
  result.should be_a(StandardError)
  result.message.should =~ /VCR/
end

Then /^(?:the )?response(?: (\d+))? for "([^\"]*)" should match \/(.+)\/$/ do |response_num, url, regex_str|
  response_num = response_num.to_i || 0
  response_num -= 1 if response_num > 0 # translate to 0-based array index.
  regex = /#{regex_str}/i
  response = @http_requests[url][response_num]
  raise response if response.is_a?(Exception)
  get_body_string(response).should =~ regex
end

Then /^there should not be a "([^\"]*)" library file$/ do |cassette_name|
  yaml_file = File.join(VCR::Config.cassette_library_dir, "#{cassette_name}.yml")
  File.exist?(yaml_file).should be_false
end

Given /^the ignore_localhost config setting is set to (true|false)$/ do |value|
  VCR::Config.ignore_localhost = eval(value)
end

Given /^a rack app is running on localhost that returns "([^"]+)" for all requests$/ do |response_string|
  @rack_server = static_rack_server(response_string)
end

When /^I make an HTTP get request to the localhost rack app within the "([^\"]*)" cassette$/ do |cassette|
  When %{I make an HTTP get request to "http://localhost:#{@rack_server.port}/" within the "#{cassette}" cassette}
end

Then /^the response for the localhost rack app should match \/(.*)\/$/ do |regex|
  Then %{the response for "http://localhost:#{@rack_server.port}/" should match /#{regex}/}
end

Given /^the "([^\"]*)" library file has a response for localhost that matches \/(.*)\/$/ do |cassette, regex|
  port = static_rack_server('localhost response').port
  Given %{the "#{cassette}" library file has a response for "http://localhost:#{port}/" that matches /#{regex}/}
end
