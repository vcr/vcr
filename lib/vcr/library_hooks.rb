module VCR
  class LibraryHooks
    def initialize
      @exclusive_hook = nil
    end

    def disabled?(hook)
      ![nil, hook].include?(@exclusive_hook)
    end

    def exclusively_enabled(hook)
      @exclusive_hook = hook
      yield
    ensure
      @exclusive_hook = nil
    end
  end
end

