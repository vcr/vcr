require 'forwardable'

module VCR
  module Normalizers
    module Body
      def initialize(*args)
        super
        # Ensure that the body is a raw string, in case the string instance
        # has been subclassed or extended with additional instance variables
        # or attributes, so that it is serialized to YAML as a raw string.
        # This is needed for rest-client.  See this ticket for more info:
        # http://github.com/myronmarston/vcr/issues/4
        self.body = String.new(body) if body.is_a?(String)
      end
    end

    module Header
      def initialize(*args)
        super
        normalize_headers
      end

    private

      def normalize_headers
        new_headers = {}

        headers.each do |k, v|
          val_array = case v
            when Array then v
            when nil then []
            else [v]
          end

          new_headers[k] = convert_to_raw_strings(val_array)
        end if headers

        self.headers = new_headers
      end

      def convert_to_raw_strings(array)
        # Ensure the values are raw strings.
        # Apparently for Paperclip uploads to S3, headers
        # get serialized with some extra stuff which leads
        # to a seg fault. See this issue for more info:
        # https://github.com/myronmarston/vcr/issues#issue/39
        array.map do |v|
          case v
            when String; String.new(v)
            when Array; convert_to_raw_strings(v)
            else v
          end
        end
      end
    end
  end

  class Request < Struct.new(:method, :uri, :body, :headers)
    include Normalizers::Header
    include Normalizers::Body

    def to_hash
      {
        'method'  => method.to_s,
        'uri'     => uri,
        'body'    => body,
        'headers' => headers
      }
    end

    def self.from_hash(hash)
      method = hash['method']
      method &&= method.to_sym
      new method,
          hash['uri'],
          hash['body'],
          hash['headers']
    end

    @@object_method = Object.instance_method(:method)
    def method(*args)
      return super if args.empty?
      @@object_method.bind(self).call(*args)
    end
  end

  class HTTPInteraction < Struct.new(:request, :response)
    extend ::Forwardable
    def_delegators :request, :uri, :method

    def to_hash
      { 'request' => request.to_hash, 'response' => response.to_hash }
    end

    def self.from_hash(hash)
      new Request.from_hash(hash.fetch('request', {})),
          Response.from_hash(hash.fetch('response', {}))
    end

    def ignore!
      # we don't want to store any additional
      # ivars on this object because that would get
      # serialized with the object...so we redefine
      # `ignored?` instead.
      (class << self; self; end).class_eval do
        undef ignored?
        def ignored?; true; end
      end
    end

    def ignored?
      false
    end

    def filter!(text, replacement_text)
      return self if [text, replacement_text].any? { |t| t.to_s.empty? }
      filter_object!(self, text, replacement_text)
    end

  private

    def filter_object!(object, text, replacement_text)
      if object.respond_to?(:gsub)
        object.gsub!(text, replacement_text) if object.include?(text)
      elsif Hash === object
        filter_hash!(object, text, replacement_text)
      elsif object.respond_to?(:each)
        # This handles nested arrays and structs
        object.each { |o| filter_object!(o, text, replacement_text) }
      end

      object
    end

    def filter_hash!(hash, text, replacement_text)
      filter_object!(hash.values, text, replacement_text)

      hash.keys.each do |k|
        new_key = filter_object!(k.dup, text, replacement_text)
        hash[new_key] = hash.delete(k) unless k == new_key
      end
    end
  end

  class Response < Struct.new(:status, :headers, :body, :http_version)
    include Normalizers::Header
    include Normalizers::Body

    def to_hash
      {
        'status'       => status.to_hash,
        'headers'      => headers,
        'body'         => body,
        'http_version' => http_version
      }
    end

    def self.from_hash(hash)
      new ResponseStatus.from_hash(hash.fetch('status', {})),
          hash['headers'],
          hash['body'],
          hash['http_version']
    end

    def update_content_length_header
      # TODO: should this be the bytesize?
      value = body ? body.length.to_s : '0'
      key = %w[ Content-Length content-length ].find { |k| headers.has_key?(k) }
      headers[key] = [value] if key
    end
  end

  class ResponseStatus < Struct.new(:code, :message)
    def to_hash
      { 'code' => code, 'message' => message }
    end

    def self.from_hash(hash)
      new hash['code'], hash['message']
    end
  end
end
