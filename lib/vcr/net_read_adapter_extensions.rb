require 'net/http'

module VCR
  module NetReadAdapter
    def new(*args, &block)
      super.extend Extension
    end

    module Extension
      def <<(str)
        (@__body_for_vcr__ ||= '') << str
        super
      end

      def to_yaml(*args)
        @__body_for_vcr__.to_yaml(*args)
      end
    end
  end
end

Net::ReadAdapter.extend VCR::NetReadAdapter