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
        # We must use string eval so that the dynamically
        # defined method can accept a block.
        instance_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{hook}(tag = nil, &block)
            hooks[#{hook.inspect}][tag] << block
          end
        RUBY
      end

      def hooks_for(hook, tag)
        for_hook = hooks[hook]
        hooks = for_hook[tag] # matching tagged hooks
        hooks += for_hook[nil] unless tag.nil? # untagged hooks
        hooks
      end
  end
end
