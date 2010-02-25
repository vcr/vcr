module VCR
  class Sandbox
    attr_reader :name

    def initialize(name, options = {})
      @name = name
    end

    def destroy!
    end
  end
end