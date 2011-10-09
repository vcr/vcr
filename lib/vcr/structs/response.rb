require 'vcr/structs/response_status'

module VCR
  class Response < Struct.new(:status, :headers, :body, :http_version)
    include Normalizers::Header
    include Normalizers::Body

    def update_content_length_header
      # TODO: should this be the bytesize?
      value = body ? body.length.to_s : '0'
      key = %w[ Content-Length content-length ].find { |k| headers.has_key?(k) }
      headers[key] = [value] if key
    end
  end
end

