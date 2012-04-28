module VCR
  class Cassette
    class Persisters
      autoload :FileSystem, 'vcr/cassette/persisters/file_system'

      def initialize
        @persisters = {}
      end

      def [](name)
        @persisters.fetch(name) do |_|
          @persisters[name] = case name
            when :file_system then FileSystem
            else raise ArgumentError, "The requested VCR cassette persister " +
                                      "(#{name.inspect}) is not registered."
          end
        end
      end

      def []=(name, value)
        if @persisters.has_key?(name)
          warn "WARNING: There is already a VCR cassette persister " +
               "registered for #{name.inspect}. Overriding it."
        end

        @persisters[name] = value
      end

    end
  end
end
