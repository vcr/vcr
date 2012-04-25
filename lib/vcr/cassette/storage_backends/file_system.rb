require 'fileutils'

module VCR
  class Cassette
    class StorageBackends
      module FileSystem
        extend self

        def storage_location
          @storage_location
        end

        # User can set where to store the files
        def storage_location=(dir)
          FileUtils.mkdir_p(dir) if dir
          @storage_location = dir ? absolute_path_for(dir) : nil
        end

        #####################################################################
        private

        def absolute_path_for(path)
          Dir.chdir(path) { Dir.pwd }
        end

      end
    end
  end
end
