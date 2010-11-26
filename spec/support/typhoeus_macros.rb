module TyphoeusMacros
  def without_typhoeus_callbacks
    before(:all) do
      @original_typhoeus_callbacks = ::Typhoeus::Hydra.global_hooks.dup
      ::Typhoeus::Hydra.clear_global_hooks
    end

    after(:all) do
      ::Typhoeus::Hydra.global_hooks = @original_typhoeus_callbacks
    end
  end
end
