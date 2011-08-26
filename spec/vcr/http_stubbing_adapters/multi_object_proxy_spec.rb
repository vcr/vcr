require 'spec_helper'

module VCR
  module HttpStubbingAdapters
    describe MultiObjectProxy do
      let(:mock1) { mock }
      let(:mock2) { mock }
      subject { described_class.new(mock1, mock2) }

      it 'raises an error when it is created with no objects' do
        expect { described_class.new }.to raise_error(ArgumentError)
      end

      it 'raises an error when one of the objects is nil' do
        expect { described_class.new(Object.new, nil) }.to raise_error(ArgumentError)
      end

      it 'is a basic object with very few of its own methods' do
        inst_methods = described_class.instance_methods.map { |m| m.to_sym }
        inst_methods.should_not include(:send, :object_id)
      end

      describe '#proxied_objects' do
        it 'returns the proxied objects' do
          subject.proxied_objects.should eq([mock1, mock2])
        end
      end

      describe '#respond_to?' do
        it 'responds to any method that any of the objects responds to' do
          mock1.stub(:respond_to?).with(:foo).and_return(true)
          mock1.stub(:respond_to?).with(:bar).and_return(false)
          mock2.stub(:respond_to?).with(:bar).and_return(true)
          mock2.stub(:respond_to?).with(:foo).and_return(false)

          subject.respond_to?(:foo).should be_true
          subject.respond_to?(:bar).should be_true
        end

        it 'does not respond to a method that none of the objects respond to' do
          subject.respond_to?(:bazz).should be_false
        end
      end

      describe 'calling a method' do
        it 'raises a no method error when none of the objects responds to the method' do
          expect { subject.some_undefined_method }.to raise_error(NoMethodError)
        end

        it 'properly proxies messages to a single object when only one object responds to the message' do
          mock1.should_not respond_to(:request_stubbed?)
          mock2.should_receive(:request_stubbed?).and_return(true)

          subject.request_stubbed?.should eq(true)
        end

        it 'proxies messages to each object' do
          mock1.should_receive(:stub_requests).with(:arg1, :arg2)
          mock2.should_receive(:stub_requests).with(:arg1, :arg2)

          subject.stub_requests(:arg1, :arg2)
        end

        [:http_connections_allowed?, :request_uri].each do |method|
          context "for ##{method}" do
            it 'raises an error if the the objects return different values' do
              mock1.should_receive(method).and_return(:return_value_1)
              mock2.should_receive(method).and_return(:return_value_2)

              expect { subject.__send__(method) }.to raise_error(/proxied objects returned different values/)
            end

            it 'returns the value returned by both objects when they return the same value' do
              mock1.should_receive(method).and_return(:return_value_1)
              mock2.should_receive(method).and_return(:return_value_1)

              subject.__send__(method).should eq(:return_value_1)
            end
          end
        end

        context 'for a non-predicate method' do
          it 'does not raise an error when the objects have different return values' do
            mock1.should_receive(:stub_requests).and_return(:val1)
            mock2.should_receive(:stub_requests).and_return(:val2)

            subject.stub_requests
          end

          it 'returns nil regardless of the return values of the objects' do
            mock1.should_receive(:stub_requests).and_return(:val1)
            mock2.should_receive(:stub_requests).and_return(:val1)

            subject.stub_requests.should be_nil
          end
        end
      end
    end
  end
end

