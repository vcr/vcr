module VCR
  # @deprecated Use #configure instead.
  # @see #configure
  def config
    warn "WARNING: `VCR.config` is deprecated.  Use VCR.configure instead."
    configure { |c| yield c }
  end

  # @private
  def self.const_missing(const)
    return super unless const == :Config
    warn "WARNING: `VCR::Config` is deprecated.  Use VCR.configuration instead."
    configuration
  end

  # @private
  def Cassette.const_missing(const)
    return super unless const == :MissingERBVariableError
    warn "WARNING: `VCR::Cassette::MissingERBVariableError` is deprecated.  Use `VCR::Errors::MissingERBVariableError` instead."
    Errors::MissingERBVariableError
  end

  class Configuration
    # @deprecated Use #hook_into instead.
    # @see #hook_into
    def stub_with(*adapters)
      warn "WARNING: `VCR.configure { |c| c.stub_with ... }` is deprecated. Use `VCR.configure { |c| c.hook_into ... }` instead."
      hook_into(*adapters)
    end
  end

  # @private
  module Deprecations
    module Middleware
      # @private
      module Faraday
        def initialize(*args)
          if block_given?
            Kernel.warn "WARNING: Passing a block to `VCR::Middleware::Faraday` is deprecated. \n" +
                        "As of VCR 2.0, you need to wrap faraday requests in VCR.use_cassette, just like with any other library hook."
          end
        end
      end
    end
  end

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
      def self.extended(base)
        Kernel.warn "WARNING: VCR::RSpec::Macros is deprecated. Use RSpec metadata options instead `:vcr => vcr_options`"
      end

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
      # @deprecated Use RSpec metadata options
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

        # Otherwise use RSpec 2/3 metadata...
        group_descriptions = []
        klass = self

        while klass.respond_to?(:metadata) && klass.metadata
          group_descriptions << klass.metadata[:description] ||
                                klass.metadata[:example_group][:description]
          klass = klass.superclass
        end

        group_descriptions.compact.reverse.join('/')
      end
    end
  end
end

