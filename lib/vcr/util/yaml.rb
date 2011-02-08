require 'yaml'

module VCR
  # Attempt to use psych if it is available.
  YAML = begin
    require 'psych'
    Psych
  rescue LoadError
    ::YAML
  end
end
