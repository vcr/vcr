require 'yaml'

module VCR
  class Cassette
    class Serializers
      # The Syck serializer. Syck is the legacy YAML engine in ruby 1.8 and 1.9.
      #
      # @see JSON
      # @see Psych
      # @see YAML
      module Syck
        extend self

        # The file extension to use for this serializer.
        #
        # @return [String] "yml"
        def file_extension
          "yml"
        end

        # Serializes the given hash using Syck.
        #
        # @param [Hash] hash the object to serialize
        # @return [String] the YAML string
        def serialize(hash)
          using_syck { ::YAML.dump(hash) }
        end

        # Deserializes the given string using Syck.
        #
        # @param [String] string the YAML string
        # @param [Hash] hash the deserialized object
        def deserialize(string)
          using_syck { ::YAML.load(string) }
        end

      private

        def using_syck
          return yield unless defined?(::YAML::ENGINE)
          original_engine = ::YAML::ENGINE.yamler
          ::YAML::ENGINE.yamler = 'syck'

          begin
            yield
          ensure
            ::YAML::ENGINE.yamler = original_engine
          end
        end
      end
    end
  end
end
