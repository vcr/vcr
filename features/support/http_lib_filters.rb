# make the values of the example row cells available as an array...
Cucumber::Ast::OutlineTable::ExampleRow.class_eval do
  def cell_values
    @cells.map { |c| c.value  }
  end
end

if RUBY_VERSION == '1.9.2'
  # For some reason, the local sinatra server locks up and never exits
  # when using patron on 1.9.2, even though it exits fine during the specs.
  def http_lib_unsupported?(lib)
    lib == 'patron'
  end

  # Filter out example rows that use libraries that are not supported on the current ruby interpreter
  Around do |scenario, block|
    unless scenario.respond_to?(:cell_values) && scenario.cell_values.any? { |v| http_lib_unsupported?(v) }
      block.call
    end
  end
end

