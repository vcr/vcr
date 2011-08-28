require 'tempfile'
stderr_file = Tempfile.new("vcr.stderr")
$stderr.reopen(stderr_file.path)
current_dir = Dir.pwd

at_exit do
  stderr_file.rewind
  lines = stderr_file.read.split("\n").uniq
  stderr_file.close!

  vcr_warnings, other_warnings = lines.partition { |line| line.include?(current_dir) }

  if vcr_warnings.any?
    puts
    puts "-" * 30 + " VCR Warnings: " + "-" * 30
    puts
    puts vcr_warnings.join("\n")
    puts
    puts "-" * 75
    puts
  end

  if other_warnings.any?
    File.open('tmp/warnings.txt', 'w') { |f| f.write(other_warnings.join("\n")) }
    puts
    puts "Non-VCR warnings written to tmp/warnings.txt"
    puts
  end

  # fail the build...
  exit(1) if vcr_warnings.any?
end

