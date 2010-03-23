require 'fileutils'

module VCR
  class Config
    class << self
      attr_reader :cassette_library_dir
      def cassette_library_dir=(cassette_library_dir)
        @cassette_library_dir = cassette_library_dir
        FileUtils.mkdir_p(cassette_library_dir) if cassette_library_dir
      end

      attr_writer :default_cassette_options
      def default_cassette_options
        @default_cassette_options ||= {}
      end

      def default_cassette_record_mode=(value)
        warn %Q{WARNING: #default_cassette_record_mode is deprecated.  Instead, use: "default_cassette_options = { :record => :#{value.to_s} }"}
        default_cassette_options.merge!(:record => value)
      end
    end
  end
end