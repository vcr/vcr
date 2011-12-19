require 'time'
require 'forwardable'

module VCR
  # @private
  module Normalizers
    module Body
      def initialize(*args)
        super
        # Ensure that the body is a raw string, in case the string instance
        # has been subclassed or extended with additional instance variables
        # or attributes, so that it is serialized to YAML as a raw string.
        # This is needed for rest-client.  See this ticket for more info:
        # http://github.com/myronmarston/vcr/issues/4
        self.body = String.new(body.to_s)
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

  module OrderedHashSerializer
    def each
      @ordered_keys.each do |key|
        yield key, self[key]
      end
    end

    if RUBY_VERSION =~ /1.9/
      # 1.9 hashes are already ordered.
      def self.apply_to(*args); end
    else
      def self.apply_to(hash, keys)
        hash.instance_variable_set(:@ordered_keys, keys)
        hash.extend self
      end
    end
  end

  class Request < Struct.new(:method, :uri, :body, :headers)
    include Normalizers::Header
    include Normalizers::Body

    def initialize(*args)
      super
      self.method = self.method.to_s.downcase.to_sym if self.method
      self.uri = without_standard_port(self.uri)
    end

    def to_hash
      {
        'method'  => method.to_s,
        'uri'     => uri,
        'body'    => body,
        'headers' => headers
      }.tap { |h| OrderedHashSerializer.apply_to(h, members) }
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

    # transforms the request into a fiber aware one
    def fiber_aware
      extend FiberAware
    end

    module FiberAware
      def proceed
        Fiber.yield
      end

      def to_proc
        lambda { proceed }
      end
    end

  private

    def without_standard_port(uri)
      return uri if uri.nil?
      u = URI(uri)
      return uri unless [['http', 80], ['https', 443]].include?([u.scheme, u.port])
      u.port = nil
      u.to_s
    end
  end

  class HTTPInteraction < Struct.new(:request, :response, :recorded_at)
    def initialize(*args)
      @ignored = false
      super
      self.recorded_at ||= Time.now
    end

    def to_hash
      {
        'request'     => request.to_hash,
        'response'    => response.to_hash,
        'recorded_at' => recorded_at.httpdate
      }.tap do |hash|
        OrderedHashSerializer.apply_to(hash, members)
      end
    end

    def self.from_hash(hash)
      new Request.from_hash(hash.fetch('request', {})),
          Response.from_hash(hash.fetch('response', {})),
          Time.httpdate(hash.fetch('recorded_at'))
    end

    def ignore!
      @ignored = true
    end

    def ignored?
      !!@ignored
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
      }.tap { |h| OrderedHashSerializer.apply_to(h, members) }
    end

    def self.from_hash(hash)
      new ResponseStatus.from_hash(hash.fetch('status', {})),
          hash['headers'],
          hash['body'],
          hash['http_version']
    end

    def update_content_length_header
      value = body ? body.bytesize.to_s : '0'
      key = %w[ Content-Length content-length ].find { |k| headers.has_key?(k) }
      headers[key] = [value] if key
    end
  end

  class ResponseStatus < Struct.new(:code, :message)
    def to_hash
      {
        'code' => code, 'message' => message
      }.tap { |h| OrderedHashSerializer.apply_to(h, members) }
    end

    def self.from_hash(hash)
      new hash['code'], hash['message']
    end
  end
end
