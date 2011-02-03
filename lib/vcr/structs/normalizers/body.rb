module VCR
  module Normalizers
    module Body
      def initialize(*args)
        super
        normalize_body
      end

      private

      def normalize_body
        # Ensure that the body is a raw string, in case the string instance
        # has been subclassed or extended with additional instance variables
        # or attributes, so that it is serialized to YAML as a raw string.
        # This is needed for rest-client.  See this ticket for more info:
        # http://github.com/myronmarston/vcr/issues/4
        self.body = case body
          when nil, ''; nil
          else String.new(body)
        end
      end
    end
  end
end
