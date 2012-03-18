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
        def storage_location=(cassette_library_dir)
          FileUtils.mkdir_p(cassette_library_dir) if cassette_library_dir
          @storage_location = cassette_library_dir ?
              absolute_path_for(cassette_library_dir) :
              nil
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
