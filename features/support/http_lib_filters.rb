# make the values of the example row cells available as an array...
Cucumber::Ast::OutlineTable::ExampleRow.class_eval do
  def cell_values
    @cells.map { |c| c.value  }
  end
end

if RUBY_VERSION == '1.9.2' || defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  # For some reason, the local sinatra server locks up and never exits
  # when using patron on 1.9.2, even though it exits fine during the specs.
  UNSUPPORTED_HTTP_LIBS = %w[ patron ]
elsif RUBY_PLATFORM == 'java'
  # These gems have C extensions and can't install on JRuby.
  UNSUPPORTED_HTTP_LIBS = %w[ typhoeus patron curb em-http-request ]
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

