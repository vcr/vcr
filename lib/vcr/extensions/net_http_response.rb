# A Net::HTTP response that has already been read raises an IOError when #read_body
# is called with a destination string or block.
#
# This causes a problem when VCR records a response--it reads the body before yielding
# the response, and if the code that is consuming the HTTP requests uses #read_body, it
# can cause an error.
#
# This is a bit of a hack, but it allows a Net::HTTP response to be "re-read"
# after it has aleady been read.  This attemps to preserve the behavior of
# #read_body, acting just as if it had never been read.

module VCR
  module Net
    module HTTPResponse
      def self.extended(object)
        object.instance_variable_set(:@__orig_body_for_vcr__, object.instance_variable_get(:@body))
      end

      def read_body(dest = nil, &block)
        if @__orig_body_for_vcr__
          if dest && block
            raise ArgumentError.new("both arg and block given for HTTP method")
          elsif dest
            dest << @__orig_body_for_vcr__
          elsif block
            @body = ::Net::ReadAdapter.new(block)
            @body << @__orig_body_for_vcr__
            @body
          else
            @body = @__orig_body_for_vcr__
          end
        else
          super
        end
      ensure
        # allow subsequent calls to #read_body to proceed as normal, without our hack...
        @__orig_body_for_vcr__ = nil
      end
    end
  end
end
