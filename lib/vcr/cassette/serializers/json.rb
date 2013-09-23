require 'multi_json'

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
        ENCODING_ERRORS = [MultiJson::DecodeError, ArgumentError]
        ENCODING_ERRORS << EncodingError if defined?(EncodingError)

        # The file extension to use for this serializer.
        #
        # @return [String] "json"
        def file_extension
          "json"
        end

        # Serializes the given hash using `MultiJson`.
        #
        # @param [Hash] hash the object to serialize
        # @return [String] the JSON string
        def serialize(hash)
          handle_encoding_errors do
            MultiJson.encode(hash)
          end
        end

        # Deserializes the given string using `MultiJson`.
        #
        # @param [String] string the JSON string
        # @return [Hash] the deserialized object
        def deserialize(string)
          handle_encoding_errors do
            MultiJson.decode(string)
          end
        end
      end
    end
  end
end
