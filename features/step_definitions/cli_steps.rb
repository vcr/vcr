require 'vcr'
require 'multi_json'

module VCRHelpers

  def normalize_cassette_hash(cassette_hash)
    cassette_hash['recorded_with'] = "VCR #{VCR.version}"
    cassette_hash['http_interactions'].map! { |h| normalize_http_interaction(h) }
    cassette_hash
  end

  def normalize_headers(object)
    object.headers = {} and return if object.headers.nil?
    object.headers = {}.tap do |hash|
      object.headers.each do |key, value|
        hash[key.downcase] = value
      end
    end
  end

  def static_timestamp
    @static_timestamp ||= Time.now
  end

  def normalize_http_interaction(hash)
    VCR::HTTPInteraction.from_hash(hash).tap do |i|
      normalize_headers(i.request)
      normalize_headers(i.response)

      i.recorded_at &&= static_timestamp
      i.request.body ||= ''
      i.response.body ||= ''
      i.response.status.message ||= ''
      i.response.adapter_metadata.clear

      # Remove non-deterministic headers and headers
      # that get added by a particular HTTP library (but not by others)
      i.response.headers.reject! { |k, v| %w[ server date connection ].include?(k) }
      i.request.headers.reject! { |k, v| %w[ accept user-agent connection expect date ].include?(k) }

      # Some HTTP libraries include an extra space ("OK " instead of "OK")
      i.response.status.message = i.response.status.message.strip

      if @scenario_parameters.to_s =~ /excon|faraday/
        # Excon/Faraday do not expose the status message or http version,
        # so we have no way to record these attributes.
        i.response.status.message = nil
        i.response.http_version = nil
      elsif @scenario_parameters.to_s.include?('webmock')
        # WebMock does not expose the HTTP version so we have no way to record it
        i.response.http_version = nil
      end
    end
  end

  def normalize_cassette_content(content)
    return content unless @scenario_parameters.to_s.include?('patron')
    cassette_hash = YAML.load(content)
    cassette_hash['http_interactions'].map! do |hash|
      VCR::HTTPInteraction.from_hash(hash).tap do |i|
        i.request.headers = (i.request.headers || {}).merge!('Expect' => [''])
      end.to_hash
    end
    YAML.dump(cassette_hash)
  end

  def modify_file(file_name, orig_text, new_text)
    in_current_dir do
      file = File.read(file_name)
      regex = /#{Regexp.escape(orig_text)}/
      expect(file).to match(regex)

      file = file.gsub(regex, new_text)
      File.open(file_name, 'w') { |f| f.write(file) }
    end
  end
end
World(VCRHelpers)

Given(/the following files do not exist:/) do |files|
  check_file_presence(files.raw.map{|file_row| file_row[0]}, false)
end

Given(/^the directory "([^"]*)" does not exist$/) do |dir|
  check_directory_presence([dir], false)
end

Given(/^a previously recorded cassette file "([^"]*)" with:$/) do |file_name, content|
  write_file(file_name, normalize_cassette_content(content))
end

Given(/^it is (.*)$/) do |date_string|
  set_env('DATE_STRING', date_string)
end

Given(/^that port numbers in "([^"]*)" are normalized to "([^"]*)"$/) do |file_name, port|
  in_current_dir do
    contents = File.read(file_name)
    contents = contents.gsub(/:\d{2,}\//, ":#{port}/")
    File.open(file_name, 'w') { |f| f.write(contents) }
  end
end

When(/^I modify the file "([^"]*)" to replace "([^"]*)" with "([^"]*)"$/) do |file_name, orig_text, new_text|
  modify_file(file_name, orig_text, new_text)
end

When(/^I append to file "([^"]*)":$/) do |file_name, content|
  append_to_file(file_name, "\n" + content)
end

When(/^I set the "([^"]*)" environment variable to "([^"]*)"$/) do |var, value|
  set_env(var, value)
end

Then(/^the file "([^"]*)" should exist$/) do |file_name|
  check_file_presence([file_name], true)
end

Then(/^it should (pass|fail) with "([^"]*)"$/) do |pass_fail, partial_output|
  assert_exit_status_and_partial_output(pass_fail == 'pass', partial_output)
end

Then(/^it should (pass|fail) with an error like:$/) do |pass_fail, partial_output|
  assert_success(pass_fail == 'pass')

  # different implementations place the exception class at different
  # places relative to the message (i.e. with a multiline error message)
  process_output = all_output.gsub(/\s*\(VCR::Errors::\w+\)/, '')

  # Some implementations include extra leading spaces, for some reason...
  process_output.gsub!(/^\s*/, '')
  partial_output.gsub!(/^\s*/, '')

  assert_partial_output(partial_output, process_output)
end

Then(/^the output should contain each of the following:$/) do |table|
  table.raw.flatten.each do |string|
    assert_partial_output(string, all_output)
  end
end

Then(/^the file "([^"]*)" should contain YAML like:$/) do |file_name, expected_content|
  actual_content = in_current_dir { File.read(file_name) }
  expect(normalize_cassette_hash(YAML.load(actual_content))).to eq(normalize_cassette_hash(YAML.load(expected_content)))
end

Then(/^the file "([^"]*)" should contain JSON like:$/) do |file_name, expected_content|
  actual_content = in_current_dir { File.read(file_name) }
  actual = MultiJson.decode(actual_content)
  expected = MultiJson.decode(expected_content.to_s)
  expect(normalize_cassette_hash(actual)).to eq(normalize_cassette_hash(expected))
end

Then(/^the file "([^"]*)" should contain compressed YAML like:$/) do |file_name, expected_content|
  actual_content = in_current_dir { File.read(file_name) }
  unzipped_content = Zlib.inflate(actual_content)
  expect(normalize_cassette_hash(YAML.load(unzipped_content))).to eq(normalize_cassette_hash(YAML.load(expected_content)))
end

Then(/^the file "([^"]*)" should contain ruby like:$/) do |file_name, expected_content|
  actual_content = in_current_dir { File.read(file_name) }
  actual = eval(actual_content)
  expected = eval(expected_content)
  expect(normalize_cassette_hash(actual)).to eq(normalize_cassette_hash(expected))
end

Then(/^the file "([^"]*)" should contain each of these:$/) do |file_name, table|
  table.raw.flatten.each do |string|
    check_file_content(file_name, string, true)
  end
end

Then(/^the file "([^"]*)" should contain a YAML fragment like:$/) do |file_name, fragment|
  in_current_dir do
    file_content = File.read(file_name)

    # Normalize by removing leading and trailing whitespace...
    file_content = file_content.split("\n").map do |line|
      # Different versions of psych use single vs. double quotes
      # And then 2.1 sometimes adds quotes...
      line.strip.gsub('"', "'").gsub("'", '')
    end.join("\n")

    expect(file_content).to include(fragment.gsub("'", ''))
  end
end

Then(/^the cassette "([^"]*)" should have the following response bodies:$/) do |file, table|
  interactions = in_current_dir { YAML.load_file(file) }['http_interactions'].map { |h| VCR::HTTPInteraction.from_hash(h) }
  actual_response_bodies = interactions.map { |i| i.response.body }
  expected_response_bodies = table.raw.flatten
  expect(actual_response_bodies).to match(expected_response_bodies)
end

Then(/^it should (pass|fail)$/) do |pass_fail|
  assert_success(pass_fail == 'pass')
end
