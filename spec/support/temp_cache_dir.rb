module TempCacheDir
  def temp_dir(dir, options = {})
    before(:each) do
      @temp_dir = dir
      @dir_remover = lambda { FileUtils.rm_rf(@temp_dir) if File.exist?(@temp_dir) }
      @dir_remover.call
      if options[:assign_to_cache_dir]
        VCR::Config.cache_dir = @temp_dir
      end
    end

    after(:each) do
      @dir_remover.call
    end
  end
end