require 'vcr/util/variable_args_block_caller'

module VCR
  module Hooks
    include VariableArgsBlockCaller

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def invoke_hook(hook, tag=nil, *args)
      hooks_for(hook, tag).map do |callback|
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

    def hooks_for(hook, tag)
      for_hook = hooks[hook]
      hooks = for_hook[tag] # matching tagged hooks
      hooks += for_hook[nil] unless tag.nil? # untagged hooks
      hooks
    end

    module ClassMethods
      def define_hook(hook)
        # We use splat args here because 1.8.7 doesn't allow default
        # values for block arguments, so we have to fake it.
        define_method hook do |*args, &block|
          if args.size > 1
            raise ArgumentError.new("wrong number of arguments (#{args.size} for 1)")
          end

          tag = args.first
          hooks[hook][tag] << block
        end
      end
    end
  end
end
