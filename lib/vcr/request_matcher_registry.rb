module VCR
  class UnregisteredMatcherError < ArgumentError; end

  class RequestMatcherRegistry
    module Matcher
      def matches?(request_1, request_2)
        call(request_1, request_2)
      end
    end

    def initialize
      @registry = {}
      register_built_ins
    end

    def register(name, &block)
      if @registry[name]
        warn "WARNING: There is already a VCR request matcher registered for #{name.inspect}. Overriding it."
      end

      block.extend Matcher
      @registry[name] = block
    end

    def [](name)
      @registry.fetch(name) do
        raise UnregisteredMatcherError.new \
          "There is no matcher registered for #{name.inspect}. " +
          "Did you mean one of #{@registry.keys.map(&:inspect).join(', ')}?"
      end
    end

  private

    def register_built_ins
      register(:method)  { |r1, r2| r1.method == r2.method }
      register(:uri)     { |r1, r2| r1.uri == r2.uri }
      register(:host)    { |r1, r2| URI(r1.uri).host == URI(r2.uri).host }
      register(:path)    { |r1, r2| URI(r1.uri).path == URI(r2.uri).path }
      register(:body)    { |r1, r2| r1.body == r2.body }
      register(:headers) { |r1, r2| r1.headers == r2.headers }
    end
  end
end

