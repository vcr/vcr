module VCR
  class Cassette
    class Cache
      def [](file_name)
        File.read(file_name)
      end

      def []=(file_name, content)
        directory = File.dirname(file_name)
        FileUtils.mkdir_p directory unless File.exist?(directory)
        File.open(file_name, 'w') { |f| f.write content }
      end

      def exists_with_content?(file_name)
        File.size?(file_name)
      end
    end
  end
end

