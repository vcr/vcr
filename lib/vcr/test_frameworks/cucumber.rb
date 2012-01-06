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

    # Adds +Before+ and +After+ cucumber hooks for the named tags that
    # will cause a VCR cassette to be used for scenarios with matching tags.
    #
    # @param [Array<String>] tag_names the cucumber scenario tags
    # @param [(optional) Hash] options the cassette options
    def tags(*tag_names)
      options = tag_names.last.is_a?(::Hash) ? tag_names.pop : {}
      tag_names.each do |tag_name|
        tag_name = "@#{tag_name}" unless tag_name =~ /\A@/
        cassette_name = "cucumber_tags/#{tag_name.gsub(/\A@/, '')}"

        # It would be nice to use an Around hook here, but
        # cucumber has a bug: background steps do not run
        # within an around hook.
        # https://gist.github.com/652968
        @main_object.Before(tag_name) do
          VCR.insert_cassette(cassette_name, options)
        end

        @main_object.After(tag_name) do
          VCR.eject_cassette
        end

        self.class.add_tag(tag_name)
      end
    end
    alias :tag :tags

    def tags_with_prefix(prefix, options={})
      tag_regex = /^(\s*(\@\w+)[,]?)+/
      Dir.glob('**/**.feature').each do |f|
        contents = File.read(f)
        cuke_tags = contents.scan(tag_regex).flatten.map(&:strip).uniq
        prefixed_tags = cuke_tags.select{|x| x.include?("@#{prefix}") }
        existing_tags = self.class.instance_variable_get("@tags")
        prefixed_tags -= existing_tags
        self.tags(*prefixed_tags, options) unless prefixed_tags.empty?
      end
    end
  end

end
