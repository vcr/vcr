module VCR
  class ResponseStatus < Struct.new(:code, :message)
    include Normalizers::StatusMessage

    def self.from_net_http_response(response)
      new(response.code.to_i, response.message)
    end
  end
end
