module VCR
  class Cassette
    class StorageBackends
      autoload :FileSystem, 'vcr/cassette/storage_backends/file_system'

      def initialize
        @storage_backends = {}
      end

      def [](name)
        @storage_backends.fetch(name) do |_|
          @storage_backends[name] = case name
            when :file_system then FileSystem
            else raise ArgumentError.new("The requested VCR cassette storage " +
                                         "backend (#{name.inspect}) is not " +
                                         "registered.")
          end
        end
      end

      def []=(name, value)
        if @storage_backends.has_key?(name)
          warn "WARNING: There is already a VCR cassette storage backend " +
               "registered for #{name.inspect}. Overriding it."
        end

        @storage_backends[name] = value
      end

    end
  end
end
