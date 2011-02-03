require 'forwardable'

module VCR
  class HTTPInteraction < Struct.new(:request, :response)
    extend ::Forwardable
    def_delegators :request, :uri, :method

    def ignore!
      @ignored = true
    end

    def ignored?
      @ignored
    end
  end
end
