module VCR
  # Integrates VCR with RSpec.
  module RSpec
    # @private
    module Metadata
      extend self

      def configure!
        ::RSpec.configure do |config|
          vcr_cassette_name_for = lambda do |metadata|
            descriptions = []

            while metadata
              vcr_options = metadata[:vcr]
              # without vcr option or just "vcr: true/false"
              vcr_options = {} unless vcr_options.is_a?(Hash)

              # removes previous descriptions, which are below the context/describe with single cassette
              descriptions.clear if vcr_options[:single_cassette]

              description = metadata[:description]
              # without description it is an "it { is_expected.to be something }" block
              description = metadata[:scoped_id] if description.empty?
              descriptions.unshift(description)

              metadata = metadata[:example_group] || metadata[:parent_example_group]
            end

            descriptions.join('/')
          end

          when_tagged_with_vcr = { :vcr => lambda { |v| !!v } }

          config.before(:each, when_tagged_with_vcr) do |ex|
            example = ex.respond_to?(:metadata) ? ex : ex.example

            cassette_name = nil
            options = example.metadata[:vcr]
            options = case options
                      when Hash #=> vcr: { cassette_name: 'foo' }
                        options.dup
                      when String #=> vcr: 'bar'
                        cassette_name = options.dup
                        {}
                      else #=> :vcr or vcr: true
                        {}
                      end

            cassette_name ||= options.delete(:cassette_name) ||
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

