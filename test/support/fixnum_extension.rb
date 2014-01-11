unless 7.respond_to?(:days)
  class Fixnum
    def days
      self *
      24 * # hours
      60 * # minutes
      60   # seconds
    end
  end
end
