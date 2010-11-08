module VCR
  module HttpStubbingAdapters
    class MultiObjectProxy < defined?(::BasicObject) ? ::BasicObject : VCR::BasicObject
      attr_reader :proxied_objects

      def initialize(*objects)
        ::Kernel.raise ::ArgumentError.new("You must pass at least one object to proxy to") if objects.empty?
        ::Kernel.raise ::ArgumentError.new("Cannot proxy to nil") if objects.any? { |o| o.nil? }

        @proxied_objects = objects
      end

      def respond_to?(message)
        proxied_objects.any? { |o| o.respond_to?(message) }
      end

      private

        def method_missing(name, *args)
          responding_proxied_objects = proxied_objects.select { |o| o.respond_to?(name) }
          return super if responding_proxied_objects.empty?

          uniq_return_vals = responding_proxied_objects.map { |o| o.__send__(name, *args) }.uniq

          return nil unless method_return_val_important?(name)
          return uniq_return_vals.first if uniq_return_vals.size == 1

          ::Kernel.raise "The proxied objects returned different values for calls to #{name}: #{uniq_return_vals.inspect}"
        end

        def method_return_val_important?(method_name)
          method_name == :request_uri || method_name.to_s =~ /\?$/
        end
    end
  end
end

