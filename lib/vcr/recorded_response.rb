module VCR
  class RecordedResponse < Struct.new(:method, :uri, :response)
  end
end