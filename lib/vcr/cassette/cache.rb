module VCR
  class Cassette
    class Cache
      def initialize
        @files = Hash.new do |files, file_name|
          files[file_name] = File.exist?(file_name) ?
                             File.read(file_name) :
                             nil
        end
      end

      def [](file_name)
        @files[file_name]
      end

      def exists_with_content?(file_name)
        @files[file_name].to_s.size > 0
      end

      # TODO: test me
      def []=(file_name, content)
        directory = File.dirname(file_name)
        FileUtils.mkdir_p directory unless File.exist?(directory)
        File.open(file_name, 'w') { |f| f.write content }
        @files[file_name] = content
      end
    end
  end
end

