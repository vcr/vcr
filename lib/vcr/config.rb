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

      attr_writer :http_stubbing_adapter
      def http_stubbing_adapter
        @http_stubbing_adapter || begin
          defined_constants = [:FakeWeb, :WebMock].select { |c| Object.const_defined?(c) }
          defined_constants[0].to_s.downcase.to_sym if defined_constants.size == 1
        end
      end
    end
  end
end