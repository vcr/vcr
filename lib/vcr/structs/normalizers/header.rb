module VCR
  module Normalizers
    module Header
      # These headers get added by the various HTTP clients automatically,
      # and we don't care about them.  We store the headers for the purposes
      # of request matching, and we only care to match on headers users
      # explicitly set.
      HEADERS_TO_SKIP = {
        'connection' => %w[ close Keep-Alive ],
        'accept'     => %w[ */* ],
        'expect'     => [''],
        'user-agent' => ["Typhoeus - http://github.com/dbalatero/typhoeus/tree/master", 'Ruby']
      }

      def initialize(*args)
        super
        normalize_headers
      end

      private

      def important_header_values(k, values)
        skip_values = HEADERS_TO_SKIP[k] || []
        values - skip_values
      end

      def normalize_headers
        new_headers = {}

        headers.each do |k, v|
          k = k.downcase

          val_array = case v
            when Array then v
            when nil then []
            else [v]
          end

          important_vals = important_header_values(k, val_array)
          next unless important_vals.size > 0

          # Ensure the values are raw strings.
          # Apparently for Paperclip uploads to S3, headers
          # get serialized with some extra stuff which leads
          # to a seg fault. See this issue for more info:
          # https://github.com/myronmarston/vcr/issues#issue/39
          string_vals = important_vals.map { |v| String.new(v) }

          new_headers[k] = string_vals
        end if headers

        self.headers = new_headers.empty? ? nil : new_headers
      end
    end
  end
end
