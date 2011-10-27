require 'multi_json'

module VCR
  class Cassette
    class Serializers
      module JSON
        extend self

        def file_extension
          "json"
        end

        def serialize(hash)
          MultiJson.encode(hash)
        end

        def deserialize(string)
          MultiJson.decode(string)
        end
      end
    end
  end
end
