#!/usr/bin/env ruby

possible_processes = `ps -o pid,command | grep jruby | grep [N]GServer`.split("\n")

if possible_processes.size == 1
  pid = possible_processes.first.strip.split(/\s+/).first.to_i
  Process.kill(9, pid)
else
  raise "Did not find 1 process as expected.  Found:\n#{possible_processes.join("\n")}"
end

