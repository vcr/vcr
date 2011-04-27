module VCR
  class Response < Struct.new(:status, :headers, :body, :body_encoding, :http_version)
    include Normalizers::Header
    include Normalizers::Body

    def self.from_net_http_response(response)
      new(
        ResponseStatus.from_net_http_response(response),
        response.to_hash,
        response.body,
        response.body.encoding.to_s,
        response.http_version,
      )
    end

    def body
      if body_encoding and self[:body]
        self[:body].force_encoding body_encoding
      end
      self[:body]
    end

    def update_content_length_header
      headers['content-length'] &&= [body.length.to_s]
    end
  end
end

