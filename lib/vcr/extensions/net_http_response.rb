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
        body_object = object.instance_variable_get(:@body)
        object.instance_variable_set(:@__orig_body__,
          case body_object
            when String then body_object
            else raise ArgumentError.new("Unexpected body object: #{body_object}")
          end
        )
      end

      def read_body(dest = nil, &block)
        if @__orig_body__
          if dest && block
            raise ArgumentError.new("both arg and block given for HTTP method")
          elsif dest
            dest << @__orig_body__
          elsif block
            @body = ::Net::ReadAdapter.new(block)
            @body << @__orig_body__
            @body
          else
            @body = @__orig_body__
          end
        else
          super
        end
      ensure
        # allow subsequent calls to #read_body to proceed as normal, without our hack...
        @__orig_body__ = nil
      end
    end
  end
end
