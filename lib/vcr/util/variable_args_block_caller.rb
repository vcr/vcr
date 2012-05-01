module VCR
  # @private
  module VariableArgsBlockCaller
    def call_block(block, *args)
      first_n_args = block.arity == -1 ? 1 : [args.size, block.arity].min
      block.call(*args.first(first_n_args))
    end
  end
end

