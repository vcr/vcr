module VCR
  # Integrates VCR with RSpec.
  module RSpec

    # Contains macro methods to assist with VCR usage. These methods are
    # intended to be used directly in an RSpec example group. To make these
    # available in your RSpec example groups, extend the module in an individual
    # example group, or configure RSpec to extend the module in all example groups.
    #
    # @example
    #   RSpec.configure do |c|
    #     c.extend VCR::RSpec::Macros
    #   end
    #
    module Macros
      include VCR::Deprecations::Macros
    end

    # @private
    module Metadata
      extend self

      def configure!
        ::RSpec.configure do |config|
          vcr_cassette_name_for = lambda do |metadata|
            description = metadata[:description]

            if example_group = metadata[:example_group]
              [vcr_cassette_name_for[example_group], description].join('/')
            else
              description
            end
          end

          config.around(:each, :vcr => lambda { |v| !!v }) do |example|
            options = example.metadata[:vcr]
            options = options.is_a?(Hash) ? options.dup : {} # in case it's just :vcr => true

            cassette_name = options.delete(:cassette_name) ||
                            vcr_cassette_name_for[example.metadata]

            VCR.use_cassette(cassette_name, options, &example)
          end
        end
      end
    end
  end
end
