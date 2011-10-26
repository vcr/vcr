require 'psych'

module VCR
  class Cassette
    class Serializers
      module Psych
        extend self

        def file_extension
          "yml"
        end

        def serialize(hash)
          ::Psych.dump(hash)
        end

        def deserialize(string)
          ::Psych.load(string)
        end
      end
    end
  end
end

