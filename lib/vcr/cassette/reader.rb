module VCR
  class Cassette
    # @private
    class Reader
      def initialize(file_name, erb)
        @file_name, @erb = file_name, erb
      end

      def read
        return file_content unless use_erb?
        binding = binding_for_variables if erb_variables
        template.result(binding)
      rescue NameError => e
        handle_name_error(e)
      end

    private

      def handle_name_error(e)
        example_hash = (erb_variables || {}).merge(e.name => 'some value')

        raise Errors::MissingERBVariableError.new(
          "The ERB in the #{@file_name} cassette file references undefined variable #{e.name}.  " +
          "Pass it to the cassette using :erb => #{ example_hash.inspect }."
        )
      end

      def use_erb?
        !!@erb
      end

      def erb_variables
        @erb if @erb.is_a?(Hash)
      end

      def file_content
        @file_content ||= File.read(@file_name)
      end

      def template
        @template ||= ERB.new(file_content)
      end

      @@struct_cache = Hash.new do |hash, attributes|
        hash[attributes] = Struct.new(*attributes)
      end

      def variables_object
        @variables_object ||= @@struct_cache[erb_variables.keys].new(*erb_variables.values)
      end

      def binding_for_variables
        @binding_for_variables ||= variables_object.instance_eval { binding }
      end
    end
  end
end
