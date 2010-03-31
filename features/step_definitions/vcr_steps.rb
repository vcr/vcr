require 'tmpdir'

module VCRHelpers
  def have_expected_response(url, regex_str)
    simple_matcher("a response from #{url} that matches /#{regex_str}/") do |responses|
      regex = /#{regex_str}/i
      responses = responses.select { |r| URI.parse(r.uri) == URI.parse(url) }
      responses.detect { |r| r.response.body =~ regex }
    end
  end

  def recorded_responses_for(cassette_name)
    yaml_file = File.join(VCR::Config.cassette_library_dir, "#{cassette_name}.yml")
    yaml = File.open(yaml_file, 'r') { |f| f.read }
    responses = YAML.load(yaml)
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

  def perform_get_with_returning_block(uri, path)
    Net::HTTP.new(uri.host, uri.port).request(Net::HTTP::Get.new(path, {})) do |response|
      return response
    end
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
    Net::HTTP.get_response(uri)
  end
end

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
    perform_get_with_returning_block(uri, path)
  end
end

When /^I make (.*HTTP (?:get|post)) requests? to "([^\"]*)"(?: and "([^\"]*)")? within the "([^\"]*)" ?(#{VCR::Cassette::VALID_RECORD_MODES.join('|')})? cassette(?:, allowing requests matching \/([^\/]+)\/)?$/ do |http_request_type, url1, url2, cassette_name, record_mode, allowed|
  options = { :record => (record_mode ? record_mode.to_sym : :new_episodes) }
  options[:allow_real_http] = lambda { |uri| uri.to_s =~ /#{allowed}/ } if allowed.to_s.size > 0
  urls = [url1, url2].select { |u| u.to_s.size > 0 }
  VCR.use_cassette(cassette_name, options) do
    urls.each do |url|
      When %{I make #{http_request_type} request to "#{url}"}
    end
  end
end

Then /^the "([^\"]*)" library file should have a response for "([^\"]*)" that matches \/(.+)\/$/ do |cassette_name, url, regex_str|
  responses = recorded_responses_for(cassette_name)
  responses.should have_expected_response(url, regex_str)
end

Then /^the "([^\"]*)" library file should have exactly (\d+) response$/ do |cassette_name, response_count|
  responses = recorded_responses_for(cassette_name)
  responses.should have(response_count.to_i).responses
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
  @http_requests[url][response_num].body.should =~ regex
end

Then /^there should not be a "([^\"]*)" library file$/ do |cassette_name|
  yaml_file = File.join(VCR::Config.cassette_library_dir, "#{cassette_name}.yml")
  File.exist?(yaml_file).should be_false
end