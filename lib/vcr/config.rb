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

      attr_accessor :adapter
      def http_stubbing_adapter
        @http_stubbing_adapter ||= case @adapter
          when :fakeweb
            VCR::HttpStubbingAdapters::FakeWeb
          else
            raise ArgumentError.new("The http stubbing adapter is not configured correctly.")
        end
      end
    end

    self.adapter = :fakeweb # set default.
  end
end