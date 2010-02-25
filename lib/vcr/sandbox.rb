module VCR
  class Sandbox
    attr_reader :name

    def initialize(name, options = {})
      @name = name
    end

    def destroy!
    end

    def recorded_responses
      @recorded_responses ||= []
    end

    def store_recorded_response!(recorded_response)
      recorded_responses << recorded_response
    end
  end
end