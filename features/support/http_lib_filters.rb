if RUBY_VERSION == '1.8.7'
  # We get timeouts on 1.8.7 w/ Patron for some reason.
  UNSUPPORTED_HTTP_LIBS = %w[ patron ]
elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  # Patron is freezing up the cukes (as it does on 1.9.2)

  # I'm not sure why em-http-request isn't working on rbx,
  # but considering the fact that VCR works with all the other
  # libs just fine and doesn't do anything for em-http-request,
  # it's probably a bug in it or rbx...so ignore it, for now.

  # I'm getting errors in the curb C extension in rbx.

  # Faraday and Typhoeus should be buildable on rbx, but the travis build times out,
  # so we skip them to speed up the build on travis.
  UNSUPPORTED_HTTP_LIBS = %w[ patron em-http-request curb faraday typhoeus ]
elsif RUBY_PLATFORM == 'java'
  # These gems have C extensions and can't install on JRuby.
  c_dependent_libs = %w[ typhoeus patron curb em-http-request ]

  # The latest version of httpclient seems to freeze up the cukes
  # on JRuby.  I'm not sure why, and there's little benefit to running
  # them on JRuby...so we just skip them.  Excon seems to have the same issue :(.
  UNSUPPORTED_HTTP_LIBS = c_dependent_libs + %w[ httpclient excon ]
end

if defined?(UNSUPPORTED_HTTP_LIBS)
  UNSUPPORTED_HTTP_LIB_REGEX = Regexp.union(*UNSUPPORTED_HTTP_LIBS)

  # Filter out example rows that use libraries that are not supported on the current ruby interpreter
  Around do |scenario, block|
    unless scenario.respond_to?(:cell_values) && scenario.cell_values.any? { |v| v =~ UNSUPPORTED_HTTP_LIB_REGEX }
      block.call
    end
  end
end

# Set a global based on the current stubbing lib so we can put special-case
# logic in our step definitions based on the http stubbing library.
Before do |scenario|
  if scenario.respond_to?(:cell_values)
    @scenario_parameters = scenario.cell_values
  else
    @scenario_parameters = nil
  end
end
