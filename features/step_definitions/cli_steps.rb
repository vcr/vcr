Given /the following files do not exist:/ do |files|
  check_file_presence(files.raw.map{|file_row| file_row[0]}, false)
end

