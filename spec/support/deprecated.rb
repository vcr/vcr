module Deprecated
  def deprecated(old_method, new_method, message)
    describe "##{old_method}" do
      disable_warnings

      it "delegates to ##{new_method}" do
        subject.should_receive(new_method).with(:arg1, :arg2).and_return(:return_value)
        subject.send(old_method, :arg1, :arg2).should == :return_value
      end

      it "prints a warning: #{message}" do
        subject.stub!(new_method)
        subject.should_receive(:warn).with(message)
        subject.send(old_method)
      end
    end
  end
end
