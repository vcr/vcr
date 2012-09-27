require 'vcr/request_matcher_registry'
require 'vcr/structs'
require 'support/limited_uri'

module VCR
  describe RequestMatcherRegistry do
    before { VCR.stub_chain(:configuration, :uri_parser) { LimitedURI } }

    def request_with(values)
      VCR::Request.new.tap do |request|
        values.each do |name, value|
          request.send("#{name}=", value)
        end
      end
    end

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

    describe "#[]" do
      it 'returns a previously registered matcher' do
        matcher = lambda { }
        subject.register(:my_matcher, &matcher)
        subject[:my_matcher].should eq(RequestMatcherRegistry::Matcher.new(matcher))
      end

      it 'raises an ArgumentError when no matcher has been registered for the given name' do
        expect {
          subject[:some_unregistered_matcher]
        }.to raise_error(VCR::Errors::UnregisteredMatcherError)
      end

      it 'returns an object that calls the named block when #matches? is called on it' do
        subject.register(:foo) { |r1, r2| r1 == 5 || r2 == 10 }
        subject[:foo].matches?(5, 0).should be_true
        subject[:foo].matches?(0, 10).should be_true
        subject[:foo].matches?(7, 7).should be_false
      end

      it 'returns an object that calls the given callable when #matches? is called on it' do
        block_called = false
        subject[lambda { |r1, r2| block_called = true }].matches?(5, 0)
        block_called.should be_true
      end
    end

    [:uri_without_param, :uri_without_params].each do |meth|
      describe "##{meth}" do
        it 'returns a matcher that can be registered for later use' do
          matcher = subject.send(meth, :foo)
          subject.register(:uri_without_foo, &matcher)
          subject[:uri_without_foo].matches?(
            request_with(:uri => 'http://example.com/search?foo=123'),
            request_with(:uri => 'http://example.com/search?foo=123')
          ).should be_true
        end

        it 'matches two requests with URIs that are identical' do
          subject[subject.send(meth, :foo)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123'),
            request_with(:uri => 'http://example.com/search?foo=123')
          ).should be_true
        end

        it 'does not match two requests with different path parts' do
          subject[subject.send(meth, :foo)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123'),
            request_with(:uri => 'http://example.com/find?foo=123')
          ).should be_false
        end

        it 'ignores the given query parameters when it is at the start' do
          subject[subject.send(meth, :foo)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123&bar=r'),
            request_with(:uri => 'http://example.com/search?foo=124&bar=r')
          ).should be_true
        end

        it 'ignores the given query parameters when it is at the end' do
          subject[subject.send(meth, :bar)].matches?(
            request_with(:uri => 'http://example.com/search?foo=124&bar=r'),
            request_with(:uri => 'http://example.com/search?foo=124&bar=q')
          ).should be_true
        end

        it 'still takes into account other query params' do
          subject[subject.send(meth, :bar)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123&bar=r'),
            request_with(:uri => 'http://example.com/search?foo=124&bar=q')
          ).should be_false
        end

        it 'handles multiple query params of the same name' do
          subject[subject.send(meth, :tag)].matches?(
            request_with(:uri => 'http://example.com/search?foo=124&tag[]=a&tag[]=b'),
            request_with(:uri => 'http://example.com/search?foo=124&tag[]=d&tag[]=e')
          ).should be_true
        end

        it 'can ignore multiple named parameters' do
          subject[subject.send(meth, :foo, :bar)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123&bar=r&baz=9'),
            request_with(:uri => 'http://example.com/search?foo=124&baz=9&bar=q')
          ).should be_true
        end

        it 'matches two requests with URIs that have no params' do
          subject[subject.send(meth, :foo, :bar)].matches?(
            request_with(:uri => 'http://example.com/search'),
            request_with(:uri => 'http://example.com/search')
          ).should be_true
        end

        it 'does not match two requests with URIs that have no params but different paths' do
          subject[subject.send(meth, :foo, :bar)].matches?(
            request_with(:uri => 'http://example.com/foo'),
            request_with(:uri => 'http://example.com/bar')
          ).should be_false
        end
      end
    end

    describe "built-ins" do
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

