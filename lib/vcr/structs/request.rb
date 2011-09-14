module VCR
  class Request < Struct.new(:method, :uri, :body, :headers)
    include Normalizers::Header
    include Normalizers::URI
    include Normalizers::Body

    @@object_method = Object.instance_method(:method)
    def method(*args)
      return super if args.empty?
      @@object_method.bind(self).call(*args)
    end

    def matcher(match_attributes)
      RequestMatcher.new(self, match_attributes)
    end
  end
end
