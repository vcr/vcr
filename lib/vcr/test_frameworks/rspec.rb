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

      # Sets up a `before` and `after` hook that will insert and eject a
      # cassette, respectively.
      #
      # @example
      #   describe "Some API Client" do
      #     use_vcr_cassette "some_api", :record => :new_episodes
      #   end
      #
      # @param [(optional) String] name the cassette name; it will be inferred by the example
      #  group descriptions if not given.
      # @param [(optional) Hash] options the cassette options
      def use_vcr_cassette(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        name    = args.first || infer_cassette_name

        before(:each) do
          VCR.insert_cassette(name, options)
        end

        after(:each) do
          VCR.eject_cassette
        end
      end

    private

      def infer_cassette_name
        # RSpec 1 exposes #description_parts; use that if its available
        return description_parts.join("/") if respond_to?(:description_parts)

        # Otherwise use RSpec 2 metadata...
        group_descriptions = []
        klass = self

        while klass.respond_to?(:metadata) && klass.metadata
          group_descriptions << klass.metadata[:example_group][:description]
          klass = klass.superclass
        end

        group_descriptions.compact.reverse.join('/')
      end
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

