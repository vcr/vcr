require 'thread'

module VCR
  class Cassette
    class Cache
      def initialize
        @files = Hash.new do |files, file_name|
          files[file_name] = File.exist?(file_name) ?
                             File.read(file_name) :
                             nil
        end

        @mutex = Mutex.new
        @file_queue = Queue.new
      end

      def [](file_name)
        @mutex.synchronize do
          @files[file_name]
        end
      end

      def exists_with_content?(file_name)
        @mutex.synchronize do
          @files[file_name].to_s.size > 0
        end
      end

      # TODO: test me
      def []=(file_name, content)
        directory = File.dirname(file_name)
        FileUtils.mkdir_p directory unless File.exist?(directory)
        File.open(file_name, 'w') { |f| f.write content }

        @mutex.synchronize do
          @files[file_name] = content
        end
      end

      def prefetch_from(directory)
        @threads = 20.times.map do
          Thread.new do
            loop do
              file_name = @file_queue.pop
              break if file_name == :exit
              @mutex.synchronize do
                @files[file_name] = File.read(file_name)
              end
            end
          end
        end

        Dir["#{directory}/**/*.yml"].each do |file_name|
          @file_queue << file_name
        end

        20.times { @file_queue << :exit }
      end
    end
  end
end

