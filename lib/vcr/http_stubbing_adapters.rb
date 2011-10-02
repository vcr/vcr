module VCR
  class HTTPStubbingAdapters
    def initialize
      @exclusive_adapter = nil
    end

    def disabled?(adapter)
      ![nil, adapter].include?(@exclusive_adapter)
    end

    def exclusively_enabled(adapter)
      @exclusive_adapter = adapter
      yield
    ensure
      @exclusive_adapter = nil
    end
  end
end

