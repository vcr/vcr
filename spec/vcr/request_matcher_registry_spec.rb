require 'vcr/request_matcher_registry'
require 'vcr/structs/http_interaction'
require 'uri'

module VCR
  describe RequestMatcherRegistry do
    describe "#register" do
      it 'registers a request matcher block that can be used later' do
        matcher_called = false
        subject.register(:my_matcher) { |*a| matcher_called = true }
        subject[:my_matcher].matches?(stub, stub)
        matcher_called.should be_true
      end

      context 'when there is already a matcher for the given name' do
        before(:each) do
          subject.register(:foo) { |*a| false }
          subject.stub :warn
        end

        it 'overrides the existing matcher' do
          subject.register(:foo) { |*a| true }
          subject[:foo].matches?(stub, stub).should be_true
        end

        it 'warns that there is a name collision' do
          subject.should_receive(:warn).with(
            /WARNING: There is already a VCR request matcher registered for :foo\. Overriding it/
          )

          subject.register(:foo) { |*a| true }
        end
      end
    end

    describe "#for" do
      it 'returns a previously registered matcher' do
        matcher = lambda { }
        subject.register(:my_matcher, &matcher)
        subject[:my_matcher].should be(matcher)
      end

      it 'raises an ArgumentError when no matcher has been registered for the given name' do
        expect {
          subject[:some_unregistered_matcher]
        }.to raise_error(UnregisteredMatcherError)
      end

      it 'returns an object that calls the block when #matches? is called on it' do
        subject.register(:foo) { |r1, r2| r1 == 5 || r2 == 10 }
        subject[:foo].matches?(5, 0).should be_true
        subject[:foo].matches?(0, 10).should be_true
        subject[:foo].matches?(7, 7).should be_false
      end
    end

    describe "built-ins" do
      def request_with(values)
        VCR::Request.new.tap do |request|
          values.each do |name, value|
            request.send("#{name}=", value)
          end
        end
      end

      describe ":method" do
        it 'matches when it is the same' do
          subject[:method].matches?(
            request_with(:method => :get),
            request_with(:method => :get)
          ).should be_true
        end

        it 'does not match when it is not the same' do
          subject[:method].matches?(
            request_with(:method => :get),
            request_with(:method => :post)
          ).should be_false
        end
      end

      describe ":uri" do
        it 'matches when it is exactly the same' do
          subject[:uri].matches?(
            request_with(:uri => 'http://foo.com/bar?baz=7'),
            request_with(:uri => 'http://foo.com/bar?baz=7')
          ).should be_true
        end

        it 'does not match when it is different' do
          subject[:uri].matches?(
            request_with(:uri => 'http://foo1.com/bar?baz=7'),
            request_with(:uri => 'http://foo2.com/bar?baz=7')
          ).should be_false
        end
      end

      describe ":host" do
        it 'matches when it is the same' do
          subject[:host].matches?(
            request_with(:uri => 'http://foo.com/bar'),
            request_with(:uri => 'http://foo.com/car')
          ).should be_true
        end

        it 'does not match when it is not the same' do
          subject[:host].matches?(
            request_with(:uri => 'http://foo.com/bar'),
            request_with(:uri => 'http://goo.com/bar')
          ).should be_false
        end
      end

      describe ":path" do
        it 'matches when it is the same' do
          subject[:path].matches?(
            request_with(:uri => 'http://foo.com/bar?a=8'),
            request_with(:uri => 'http://goo.com/bar?a=9')
          ).should be_true
        end

        it 'does not match when it is not the same' do
          subject[:path].matches?(
            request_with(:uri => 'http://foo.com/bar?a=8'),
            request_with(:uri => 'http://foo.com/car?a=8')
          ).should be_false
        end
      end

      describe ":body" do
        it 'matches when it is the same' do
          subject[:body].matches?(
            request_with(:body => 'foo'),
            request_with(:body => 'foo')
          ).should be_true
        end

        it 'does not match when it is not the same' do
          subject[:body].matches?(
            request_with(:body => 'foo'),
            request_with(:body => 'bar')
          ).should be_false
        end
      end

      describe ":headers" do
        it 'matches when it is the same' do
          subject[:headers].matches?(
            request_with(:headers => { 'a' => 1, 'b' => 2 }),
            request_with(:headers => { 'b' => 2, 'a' => 1 })
          ).should be_true
        end

        it 'does not match when it is not the same' do
          subject[:headers].matches?(
            request_with(:headers => { 'a' => 3, 'b' => 2 }),
            request_with(:headers => { 'b' => 2, 'a' => 1 })
          ).should be_false
        end
      end
    end
  end
end

