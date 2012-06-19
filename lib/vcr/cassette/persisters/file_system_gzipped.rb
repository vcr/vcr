require 'zlib'

module VCR
  class Cassette
    class Persisters
      # The only built-in cassette persister. Persists cassettes to the file system.
      module FileSystemGzipped
        extend FileSystem
        extend self

        # @private
        def absolute_path_to_file(file_name)
          path = super
          path << ".gz" unless path.nil?
          path
        end

      private

        def read_file(path)
          file = File.open(path)
          gzip_reader = Zlib::GzipReader.new(file)
          content = gzip_reader.read
          gzip_reader.close
          content
        end

        def write_file(path, content)
          Zlib::GzipWriter.open(path) do |gz|
            gz.write(content)
          end
        end
      end
    end
  end
end