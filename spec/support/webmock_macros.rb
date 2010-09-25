module WebMockMacros
  def without_webmock_callbacks
    before(:all) do
      @original_webmock_callbacks = ::WebMock::CallbackRegistry.callbacks
      ::WebMock::CallbackRegistry.reset
    end

    after(:all) do
      @original_webmock_callbacks.each do |cb|
        ::WebMock::CallbackRegistry.add_callback(cb[:options], cb[:block])
      end
    end
  end
end
