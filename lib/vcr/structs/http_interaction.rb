require 'forwardable'
require 'vcr/structs/normalizers/body'
require 'vcr/structs/normalizers/header'
require 'vcr/structs/normalizers/status_message'
require 'vcr/structs/normalizers/uri'
require 'vcr/structs/request'
require 'vcr/structs/response'

module VCR
  class HTTPInteraction < Struct.new(:request, :response)
    extend ::Forwardable
    def_delegators :request, :uri, :method

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
end
