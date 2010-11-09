Given /the following files do not exist:/ do |files|
  check_file_presence(files.raw.map{|file_row| file_row[0]}, false)
end

Given /^the directory "([^"]*)" does not exist$/ do |dir|
  check_directory_presence([dir], false)
end

Then /^the file "([^"]*)" should exist$/ do |file_name|
  check_file_presence([file_name], true)
end

Then /^it should (pass|fail) with "([^"]*)"$/ do |pass_fail, partial_output|
  assert_exit_status_and_partial_output(pass_fail == 'pass', partial_output)
end

