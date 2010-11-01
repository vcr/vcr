module VCR
  # taken directly from backports:
  # https://github.com/marcandre/backports/blob/v1.18.2/lib/backports/basic_object.rb
  class BasicObject
    KEEP = [:instance_eval, :instance_exec, :__send__,
            "instance_eval", "instance_exec", "__send__"]
    # undefine almost all instance methods
    begin
      old_verbose, $VERBOSE = $VERBOSE, nil # silence the warning for undefining __id__
      (instance_methods - KEEP).each do |method|
        undef_method method
      end
    ensure
      $VERBOSE = old_verbose
    end

    class << self
      def === (cmp)
        true
      end

      # Let's try to keep things clean, in case methods have been added to Object
      # either directly or through an included module.
      # We'll do this whenever a class is derived from BasicObject
      # Ideally, we'd do this by trapping Object.method_added
      # and M.method_added for any module M included in Object or a submodule
      # Seems really though to get right, but pull requests welcome ;-)
      def inherited(sub)
        BasicObject.class_eval do
          (instance_methods - KEEP).each do |method|
            if Object.method_defined?(method) && instance_method(method).owner == Object.instance_method(method).owner
              undef_method method
            end
          end
        end
      end
    end
  end
end
