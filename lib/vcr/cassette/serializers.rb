require 'yaml'

module VCR
  class Cassette
    class Serializers
      def initialize
        @serializers = {}
        register_built_ins
      end

      def [](name)
        @serializers[name]
      end

      def []=(name, value)
        if @serializers.has_key?(name)
          warn "WARNING: There is already a VCR cassette serializer registered for #{name.inspect}. Overriding it."
        end

        @serializers[name] = value
      end

    private

      def register_built_ins
        self[:yaml] = YAML
      end

      module YAML
        extend self

        def file_extension
          "yml"
        end

        def serialize(hash)
          ::YAML.dump(hash)
        end

        def deserialize(string)
          ::YAML.load(string)
        end
      end
    end
  end
end

