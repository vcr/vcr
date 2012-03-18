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
            when :db then Db
            when :file_system then FileSystem
            else raise ArgumentError.new("The requested VCR cassette storage " +
                                         "backend (#{name.inspect}) is not " +
                                         "registered.")
          end
        end
      end

      def []=(name, value)
        if @storage_backends.has_key?(name)
          warn 'backend named #{name.inspect} is being overwritten.'
        end
        @storage_backends[name] = value
      end

    end
  end
end
