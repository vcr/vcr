module VCR
  module Normalizers
    module Header
      def initialize(*args)
        super
        normalize_headers
      end

    private

      def normalize_headers
        new_headers = {}

        headers.each do |k, v|
          val_array = case v
            when Array then v
            when nil then []
            else [v]
          end

          new_headers[k] = convert_to_raw_strings(val_array)
        end if headers

        self.headers = new_headers
      end

      def convert_to_raw_strings(array)
        # Ensure the values are raw strings.
        # Apparently for Paperclip uploads to S3, headers
        # get serialized with some extra stuff which leads
        # to a seg fault. See this issue for more info:
        # https://github.com/myronmarston/vcr/issues#issue/39
        array.map do |v|
          case v
            when String; String.new(v)
            when Array; convert_to_raw_strings(v)
            else v
          end
        end
      end
    end
  end
end
