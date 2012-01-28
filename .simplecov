SimpleCov.start do
  add_filter "/spec"
  add_filter "/features"

  # internet_connection mostly contains logic copied from the ruby 1.8.7
  # stdlib for which I haven't written tests.
  add_filter "internet_connection"
end

