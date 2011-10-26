require 'yaml'

module VCR
  class Cassette
    class Serializers
      module Syck
        extend self

        def file_extension
          "yml"
        end

        def serialize(hash)
          using_syck { ::YAML.dump(hash) }
        end

        def deserialize(string)
          using_syck { ::YAML.load(string) }
        end

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
