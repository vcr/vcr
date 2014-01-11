RUBY_INTERPRETER = if RUBY_PLATFORM == 'java'
  :jruby
elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  :rubinius
else
  :mri
end
