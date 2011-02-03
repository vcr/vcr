module VCR
  module Normalizers
    module StatusMessage
      def initialize(*args)
        super
        normalize_status_message
      end

      private

      def normalize_status_message
        self.message = message.strip if message
        self.message = nil if message == ''
      end
    end
  end
end
