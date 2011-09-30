module VCR
  class CucumberTags
    class << self
      def tags
        @tags.dup
      end

      def add_tag(tag)
        @tags << tag
      end
    end

    @tags = []
    def initialize(main_object)
      @main_object = main_object
    end

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
  end
end
