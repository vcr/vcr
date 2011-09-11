module VCR
  module Hooks
    include VariableArgsBlockCaller

    def invoke_hook(hook, tag, *args)
      hooks_for(hook, tag).each do |callback|
        call_block(callback, *args)
      end
    end

    def clear_hooks
      hooks.clear
    end

    private

      def hooks
        @hooks ||= Hash.new do |hook_type_hash, hook_type|
          hook_type_hash[hook_type] = Hash.new do |tag_hash, tag|
            tag_hash[tag] = []
          end
        end
      end

      def define_hook(hook)
        singleton_class = (class << self; self; end)
        # We use splat args here because 1.8.7 doesn't allow default
        # values for block arguments, so we have to fake it.
        singleton_class.send(:define_method, hook) do |*args, &block|
          if args.size > 1
            raise ArgumentError.new("wrong number of arguments (#{args.size} for 1)")
          end

          tag = args.first
          hooks[hook][tag] << block
        end
      end

      def hooks_for(hook, tag)
        for_hook = hooks[hook]
        hooks = for_hook[tag] # matching tagged hooks
        hooks += for_hook[nil] unless tag.nil? # untagged hooks
        hooks
      end
  end
end
