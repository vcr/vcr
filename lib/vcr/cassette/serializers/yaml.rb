require 'yaml'

module VCR
  class Cassette
    class Serializers
      # The YAML serializer. This will use either Psych or Syck, which ever your
      # ruby interpreter defaults to. You can also force VCR to use Psych or Syck by
      # using one of those serializers.
      #
      # @see JSON
      # @see Psych
      # @see Syck
      module YAML
        extend self
        extend EncodingErrorHandling

        # @private
        ENCODING_ERRORS = [ArgumentError]

        # The file extension to use for this serializer.
        #
        # @return [String] "yml"
        def file_extension
          "yml"
        end

        # Serializes the given hash using YAML.
        #
        # @param [Hash] hash the object to serialize
        # @return [String] the YAML string
        def serialize(hash)
          handle_encoding_errors do
            ::YAML.dump(hash)
          end
        end

        # Deserializes the given string using YAML.
        #
        # @param [String] string the YAML string
        # @return [Hash] the deserialized object
        def deserialize(string)
          handle_encoding_errors do
            ::YAML.load(string)
          end
        end
      end
    end
  end
end

