module VCR
  # Integrates VCR with RSpec.
  module RSpec
    # @private
    module Metadata
      extend self

      def configure!
        ::RSpec.configure do |config|
          vcr_cassette_name_for = lambda do |metadata|
            description = metadata[:description]
            example_group = if metadata.key?(:example_group)
                              metadata[:example_group]
                            else
                              metadata[:parent_example_group]
                            end

            if example_group
              [vcr_cassette_name_for[example_group], description].join('/')
            else
              description
            end
          end

          when_tagged_with_vcr = { :vcr => lambda { |v| !!v } }

          config.before(:each, when_tagged_with_vcr) do |ex|
            example = ex.respond_to?(:metadata) ? ex : ex.example

            options = example.metadata[:vcr]
            options = options.is_a?(Hash) ? options.dup : {} # in case it's just :vcr => true

            cassette_name = options.delete(:cassette_name) ||
                            vcr_cassette_name_for[example.metadata]
            VCR.insert_cassette(cassette_name, options)
          end

          config.after(:each, when_tagged_with_vcr) do |ex|
            example = ex.respond_to?(:metadata) ? ex : ex.example
            VCR.eject_cassette(:skip_no_unused_interactions_assertion => !!example.exception)
          end
        end
      end
    end
  end
end

