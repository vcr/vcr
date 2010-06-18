require 'tmpdir'

module VCRHelpers
  def have_expected_response(url, regex_str)
    simple_matcher("a response from #{url} that matches /#{regex_str}/") do |responses|
      selector = case url
        when String then lambda { |r| URI.parse(r.uri) == URI.parse(url) }
        when Regexp then lambda { |r| r.uri == url }
        else raise ArgumentError.new("Unexpected url: #{url.class.to_s}: #{url.inspect}")
      end

      responses = responses.select(&selector)
      regex = /#{regex_str}/i
      responses.detect { |r| get_body_string(r.response) =~ regex }
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
  recorded_interactions_for(cassette_name).should have_expected_response(/#{url_regex}/, body_regex)
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
    http_get(uri)
  end
end

When /^I make (.*) requests? to "([^\"]*)"(?: and "([^\"]*)")? within the "([^\"]*)" ?(#{VCR::Cassette::VALID_RECORD_MODES.join('|')})? cassette$/ do |http_request_type, url1, url2, cassette_name, record_mode|
  options = { :record => (record_mode ? record_mode.to_sym : :new_episodes) }
  urls = [url1, url2].select { |u| u.to_s.size > 0 }
  VCR.use_cassette(cassette_name, options) do
    urls.each do |url|
      When %{I make #{http_request_type} request to "#{url}"}
    end
  end
end

Then /^the "([^\"]*)" library file should have a response for "([^\"]*)" that matches \/(.+)\/$/ do |cassette_name, url, regex_str|
  interactions = recorded_interactions_for(cassette_name)
  interactions.should have_expected_response(url, regex_str)
end

Then /^the "([^\"]*)" library file should have exactly (\d+) response$/ do |cassette_name, response_count|
  interactions = recorded_interactions_for(cassette_name)
  interactions.should have(response_count.to_i).responses
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
  get_body_string(@http_requests[url][response_num]).should =~ regex
end

Then /^there should not be a "([^\"]*)" library file$/ do |cassette_name|
  yaml_file = File.join(VCR::Config.cassette_library_dir, "#{cassette_name}.yml")
  File.exist?(yaml_file).should be_false
end