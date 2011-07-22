module VCR
  class Response < Struct.new(:status, :headers, :body, :http_version)
    include Normalizers::Header
    include Normalizers::Body

    def self.from_net_http_response(response)
      new(
        ResponseStatus.from_net_http_response(response),
        response.to_hash,
        response.body,
        response.http_version
      )
    end

    def update_content_length_header
      headers['content-length'] &&= [body ? body.length.to_s : '0']
    end
  end
end

