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
        tag_name = "@#{tag_name}" unless tag_name =~ /^@/
        cassette_name = "cucumber_tags/#{tag_name.gsub(/\A@/, '')}"

        @main_object.instance_eval do
          Before(tag_name) do
            VCR.insert_cassette(cassette_name, options)
          end

          After(tag_name) do
            VCR.eject_cassette
          end
        end
        self.class.add_tag(tag_name)
      end
    end
    alias :tag :tags
  end
end