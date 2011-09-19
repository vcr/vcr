require 'vcr/structs/response_status'

module VCR
  class Response < Struct.new(:status, :headers, :body, :http_version)
    include Normalizers::Header
    include Normalizers::Body

    def update_content_length_header
      headers['content-length'] &&= [body ? body.length.to_s : '0']
    end
  end
end

