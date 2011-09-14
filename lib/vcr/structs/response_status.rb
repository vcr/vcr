module VCR
  class ResponseStatus < Struct.new(:code, :message)
    include Normalizers::StatusMessage
  end
end
