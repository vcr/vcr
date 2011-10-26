require 'yaml'

module VCR
  class Cassette
    class Serializers
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

