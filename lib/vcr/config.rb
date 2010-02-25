require 'fileutils'

module VCR
  class Config
    class << self
      attr_reader :cache_dir
      def cache_dir=(cache_dir)
        @cache_dir = cache_dir
        FileUtils.mkdir_p(cache_dir) if cache_dir
      end
    end
  end
end