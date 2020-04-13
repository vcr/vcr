require 'json'

module VCR
  class Cassette
    class Serializers
      # The JSON serializer. Uses `MultiJson` under the covers.
      #
      # @see Psych
      # @see Syck
      # @see YAML
      module JSON
        extend self
        extend EncodingErrorHandling

        # @private
        ENCODING_ERRORS = [ArgumentError]
        ENCODING_ERRORS << ::JSON::GeneratorError

        # The file extension to use for this serializer.
        #
        # @return [String] "json"
        def file_extension
          "json"
        end

        # Serializes the given hash using `JSON`.
        #
        # @param [Hash] hash the object to serialize
        # @return [String] the JSON string
        def serialize(hash)
          handle_encoding_errors do
            ::JSON.generate(hash)
          end
        end

        # Deserializes the given string using `JSON`.
        #
        # @param [String] string the JSON string
        # @return [Hash] the deserialized object
        def deserialize(string)
          handle_encoding_errors do
            ::JSON.parse(string)
          end
        end
      end
    end
  end
end
