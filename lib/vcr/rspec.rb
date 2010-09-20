require 'vcr'

module VCR
  module RSpec
    module Macros
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
        group_descriptions = []
        klass = self

        while klass.respond_to?(:metadata) && klass.metadata
          group_descriptions << klass.metadata[:example_group][:description]
          klass = klass.superclass
        end

        group_descriptions.compact.reverse.join('/')
      end
    end
  end
end

