module VCR
  # Integrates VCR with RSpec.
  module MiniTest
    # @private
    module Spec
      extend self

      def configure!
        # require_relative "minitest_monkey"
        run_before = lambda do |example|
          test_info = example.class.name.split("::").map {|e| e.downcase.gsub(/\s/, "_")}.reject(&:empty?)
          name = spec_name.downcase.gsub(/[^\w\/]+/, "_")
          path = "test/cassettes/" + [(test_info[0].gsub(/\s/, "_").gsub(/[^\w\/]+/, "_")), test_info[1]].join("/")
          FileUtils.mkdir_p(path) unless File.directory?(path)
          VCR.configure do |c|
            c.cassette_library_dir = path
          end
          VCR.insert_cassette name
        end

        run_after = lambda do |example|
          VCR.eject_cassette
          VCR.configure do |c|
            c.cassette_library_dir = 'test/cassettes'
          end
        end

        ::MiniTest::Spec.before :each, &run_before

        ::MiniTest::Spec.after :each, &run_after
      end
    end
  end
end
