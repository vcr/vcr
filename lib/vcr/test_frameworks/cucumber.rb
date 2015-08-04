module VCR
  # Provides integration with Cucumber using tags.
  class CucumberTags
    class << self
      # @private
      def tags
        @tags.dup
      end

      # @private
      def add_tag(tag)
        @tags << tag
      end
    end

    @tags = []

    # @private
    def initialize(main_object)
      @main_object = main_object
    end

    # Adds `Before` and `After` cucumber hooks for the named tags that
    # will cause a VCR cassette to be used for scenarios with matching tags.
    #
    # @param [Array<String>] tag_names the cucumber scenario tags
    # @param [(optional) Hash] options the cassette options. Specify
    #   `:use_scenario_name => true` to automatically name the
    #   cassette according to the scenario name.
    def tags(*tag_names)
      original_options = tag_names.last.is_a?(::Hash) ? tag_names.pop : {}
      tag_names.each do |tag_name|
        tag_name = "@#{tag_name}" unless tag_name =~ /\A@/

        # It would be nice to use an Around hook here, but
        # cucumber has a bug: background steps do not run
        # within an around hook.
        # https://gist.github.com/652968
        @main_object.Before(tag_name) do |scenario|
          options = original_options.dup

          cassette_name = if options.delete(:use_scenario_name)
            feature = scenario.respond_to?(:scenario_outline) ? scenario.scenario_outline.feature : scenario.feature
            # Cucumber 1.x provides the full description under feature.name, including leading \n if no name is provided.
            # Cucumber 2.x provides only the text from 'Feature:' up to the first newline as feature.name.
            name = feature.name.split("\n").first # this gets the feature name in Cucumber 1.x, or otherwise nil
            name ||= feature.name                 # this gets the feature name in Cucumber 2.x
            name << "/#{scenario.scenario_outline.name}" if scenario.respond_to?(:scenario_outline)
            name << "/#{scenario.name.split("\n").first}"
            name
          else
            "cucumber_tags/#{tag_name.gsub(/\A@/, '')}"
          end

          VCR.insert_cassette(cassette_name, options)
        end

        @main_object.After(tag_name) do |scenario|
          VCR.eject_cassette(:skip_no_unused_interactions_assertion => scenario.failed?)
        end

        self.class.add_tag(tag_name)
      end
    end
    alias :tag :tags
  end
end
