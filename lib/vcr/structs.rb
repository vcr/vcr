require 'base64'
require 'delegate'
require 'time'

module VCR
  # @private
  module Normalizers
    # @private
    module Body
      def self.included(klass)
        klass.extend ClassMethods
      end

      # @private
      module ClassMethods
        def body_from(hash_or_string)
          return hash_or_string unless hash_or_string.is_a?(Hash)

          if hash_or_string.has_key?('base64_string')
            string = Base64.decode64(hash_or_string['base64_string'])
            force_encode_string(string, hash_or_string['encoding'])
          else
            hash_or_string['string']
          end
        end

        if "".respond_to?(:encoding)
          def force_encode_string(string, encoding)
            return string unless encoding
            string.force_encoding(encoding)
          end
        else
          def force_encode_string(string, encoding)
            string
          end
        end
      end

      def initialize(*args)
        super
        # Ensure that the body is a raw string, in case the string instance
        # has been subclassed or extended with additional instance variables
        # or attributes, so that it is serialized to YAML as a raw string.
        # This is needed for rest-client.  See this ticket for more info:
        # http://github.com/myronmarston/vcr/issues/4
        self.body = String.new(body.to_s)
      end

    private

      def serializable_body
        if VCR.configuration.preserve_exact_body_bytes_for?(self)
          base_body_hash(body).merge('base64_string' => Base64.encode64(body))
        else
          base_body_hash(body).merge('string' => body)
        end
      end

      if ''.respond_to?(:encoding)
        def base_body_hash(body)
          { 'encoding' => body.encoding.name }
        end
      else
        def base_body_hash(body)
          { }
        end
      end
    end

    # @private
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

  # @private
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

  # The request of an {HTTPInteraction}.
  #
  # @attr [Symbol] method the HTTP method (i.e. :head, :options, :get, :post, :put, :patch or :delete)
  # @attr [String] uri the request URI
  # @attr [String, nil] body the request body
  # @attr [Hash{String => Array<String>}] headers the request headers
  class Request < Struct.new(:method, :uri, :body, :headers)
    include Normalizers::Header
    include Normalizers::Body

    def initialize(*args)
      super
      self.method = self.method.to_s.downcase.to_sym if self.method
      self.uri = without_standard_port(self.uri)
    end

    # Builds a serializable hash from the request data.
    #
    # @return [Hash] hash that represents this request and can be easily
    #  serialized.
    # @see Request.from_hash
    def to_hash
      {
        'method'  => method.to_s,
        'uri'     => uri,
        'body'    => serializable_body,
        'headers' => headers
      }.tap { |h| OrderedHashSerializer.apply_to(h, members) }
    end

    # Constructs a new instance from a hash.
    #
    # @param [Hash] hash the hash to use to construct the instance.
    # @return [Request] the request
    def self.from_hash(hash)
      method = hash['method']
      method &&= method.to_sym
      new method,
          hash['uri'],
          body_from(hash['body']),
          hash['headers']
    end

    @@object_method = Object.instance_method(:method)
    def method(*args)
      return super if args.empty?
      @@object_method.bind(self).call(*args)
    end

    # Decorates a {Request} with its current type.
    class Typed < DelegateClass(self)
      # @return [Symbol] One of `:ignored`, `:stubbed`, `:recordable` or `:unhandled`.
      attr_reader :type

      # @param [Request] request the request
      # @param [Symbol] type the type. Should be one of `:ignored`, `:stubbed`, `:recordable` or `:unhandled`.
      def initialize(request, type)
        @type = type
        super(request)
      end

      # @return [Boolean] whether or not this request is being ignored
      def ignored?
        type == :ignored
      end

      # @return [Boolean] whether or not this request will be stubbed
      def stubbed?
        type == :stubbed
      end

      # @return [Boolean] whether or not this request will be recorded.
      def recordable?
        type == :recordable
      end

      # @return [Boolean] whether or not VCR knows how to handle this request.
      def unhandled?
        type == :unhandled
      end

      # @return [Boolean] whether or not this request will be made for real.
      # @note VCR allows `:ignored` and `:recordable` requests to be made for real.
      def real?
        ignored? || recordable?
      end

      undef method
    end

    # Provides fiber-awareness for the {VCR::Configuration#around_http_request} hook.
    class FiberAware < DelegateClass(Typed)
      # Yields the fiber so the request can proceed.
      #
      # @return [VCR::Response] the response from the request
      def proceed
        Fiber.yield
      end

      # Builds a proc that allows the request to proceed when called.
      # This allows you to treat the request as a proc and pass it on
      # to a method that yields (at which point the request will proceed).
      #
      # @return [Proc] the proc
      def to_proc
        lambda { proceed }
      end

      undef method
    end

    # Transforms the request into a fiber aware one by extending
    # the {FiberAware} module onto the instance. Necessary for the
    # {VCR::Configuration#around_http_request} hook.
    #
    # @return [Request] the request instance
    def fiber_aware
      extend FiberAware
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

  # Represents a single interaction over HTTP, containing a request and a response.
  #
  # @attr [Request] request the request
  # @attr [Response] response the response
  # @attr [Time] recorded_at when this HTTP interaction was recorded
  class HTTPInteraction < Struct.new(:request, :response, :recorded_at)
    def initialize(*args)
      super
      self.recorded_at ||= Time.now
    end

    # Builds a serializable hash from the HTTP interaction data.
    #
    # @return [Hash] hash that represents this HTTP interaction
    #  and can be easily serialized.
    # @see HTTPInteraction.from_hash
    def to_hash
      {
        'request'     => request.to_hash,
        'response'    => response.to_hash,
        'recorded_at' => recorded_at.httpdate
      }.tap do |hash|
        OrderedHashSerializer.apply_to(hash, members)
      end
    end

    # Constructs a new instance from a hash.
    #
    # @param [Hash] hash the hash to use to construct the instance.
    # @return [HTTPInteraction] the HTTP interaction
    def self.from_hash(hash)
      new Request.from_hash(hash.fetch('request', {})),
          Response.from_hash(hash.fetch('response', {})),
          Time.httpdate(hash.fetch('recorded_at'))
    end

    # @return [HookAware] an instance with additional capabilities
    #  suitable for use in `before_record` and `before_playback` hooks.
    def hook_aware
      HookAware.new(self)
    end

    # Decorates an {HTTPInteraction} with additional methods useful
    # for a `before_record` or `before_playback` hook.
    class HookAware < DelegateClass(HTTPInteraction)
      def initialize(http_interaction)
        @ignored = false
        super
      end

      # Flags the HTTP interaction so that VCR ignores it. This is useful in
      # a {VCR::Configuration#before_record} or {VCR::Configuration#before_playback}
      # hook so that VCR does not record or play it back.
      # @see #ignored?
      def ignore!
        @ignored = true
      end

      # @return [Boolean] whether or not this HTTP interaction should be ignored.
      # @see #ignore!
      def ignored?
        !!@ignored
      end

      # Replaces a string in any part of the HTTP interaction (headers, request body,
      # response body, etc) with the given replacement text.
      #
      # @param [String] text the text to replace
      # @param [String] replacement_text the text to put in its place
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
  end

  # The response of an {HTTPInteraction}.
  #
  # @attr [ResponseStatus] status the status of the response
  # @attr [Hash{String => Array<String>}] headers the response headers
  # @attr [String] body the response body
  # @attr [nil, String] http_version the HTTP version
  class Response < Struct.new(:status, :headers, :body, :http_version)
    include Normalizers::Header
    include Normalizers::Body

    # Builds a serializable hash from the response data.
    #
    # @return [Hash] hash that represents this response
    #  and can be easily serialized.
    # @see Response.from_hash
    def to_hash
      {
        'status'       => status.to_hash,
        'headers'      => headers,
        'body'         => serializable_body,
        'http_version' => http_version
      }.tap { |h| OrderedHashSerializer.apply_to(h, members) }
    end

    # Constructs a new instance from a hash.
    #
    # @param [Hash] hash the hash to use to construct the instance.
    # @return [Response] the response
    def self.from_hash(hash)
      new ResponseStatus.from_hash(hash.fetch('status', {})),
          hash['headers'],
          body_from(hash['body']),
          hash['http_version']
    end

    # Updates the Content-Length response header so that it is
    # accurate for the response body.
    def update_content_length_header
      value = body ? body.bytesize.to_s : '0'
      key = %w[ Content-Length content-length ].find { |k| headers.has_key?(k) }
      headers[key] = [value] if key
    end
  end

  # The response status of an {HTTPInteraction}.
  #
  # @attr [Integer] code the HTTP status code
  # @attr [String] message the HTTP status message (e.g. "OK" for a status of 200)
  class ResponseStatus < Struct.new(:code, :message)
    # Builds a serializable hash from the response status data.
    #
    # @return [Hash] hash that represents this response status
    #  and can be easily serialized.
    # @see ResponseStatus.from_hash
    def to_hash
      {
        'code' => code, 'message' => message
      }.tap { |h| OrderedHashSerializer.apply_to(h, members) }
    end

    # Constructs a new instance from a hash.
    #
    # @param [Hash] hash the hash to use to construct the instance.
    # @return [ResponseStatus] the response status
    def self.from_hash(hash)
      new hash['code'], hash['message']
    end
  end
end
