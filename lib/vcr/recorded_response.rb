module VCR
  class RecordedResponse < Struct.new(:method, :uri, :response, :request_body, :request_headers)
  end
end