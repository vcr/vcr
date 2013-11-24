require 'vcr/request_matcher_registry'
require 'vcr/structs'
require 'support/limited_uri'
require 'cgi'
require 'support/configuration_stubbing'

module VCR
  describe RequestMatcherRegistry do
    include_context "configuration stubbing"

    before do
      allow(config).to receive(:uri_parser) { LimitedURI }
      allow(config).to receive(:query_parser) { CGI.method(:parse) }
    end

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
        subject[:my_matcher].matches?(double, double)
        expect(matcher_called).to be true
      end

      context 'when there is already a matcher for the given name' do
        before(:each) do
          subject.register(:foo) { |*a| false }
          allow(subject).to receive :warn
        end

        it 'overrides the existing matcher' do
          subject.register(:foo) { |*a| true }
          expect(subject[:foo].matches?(double, double)).to be true
        end

        it 'warns that there is a name collision' do
          expect(subject).to receive(:warn).with(
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
        expect(subject[:my_matcher]).to eq(RequestMatcherRegistry::Matcher.new(matcher))
      end

      it 'raises an ArgumentError when no matcher has been registered for the given name' do
        expect {
          subject[:some_unregistered_matcher]
        }.to raise_error(VCR::Errors::UnregisteredMatcherError)
      end

      it 'returns an object that calls the named block when #matches? is called on it' do
        subject.register(:foo) { |r1, r2| r1 == 5 || r2 == 10 }
        expect(subject[:foo].matches?(5, 0)).to be true
        expect(subject[:foo].matches?(0, 10)).to be true
        expect(subject[:foo].matches?(7, 7)).to be false
      end

      it 'returns an object that calls the given callable when #matches? is called on it' do
        block_called = false
        subject[lambda { |r1, r2| block_called = true }].matches?(5, 0)
        expect(block_called).to be true
      end
    end

    [:uri_without_param, :uri_without_params].each do |meth|
      describe "##{meth}" do
        it 'returns a matcher that can be registered for later use' do
          matcher = subject.send(meth, :foo)
          subject.register(:uri_without_foo, &matcher)
          matches = subject[:uri_without_foo].matches?(
            request_with(:uri => 'http://example.com/search?foo=123'),
            request_with(:uri => 'http://example.com/search?foo=123')
          )
          expect(matches).to be true
        end

        it 'matches two requests with URIs that are identical' do
          matches = subject[subject.send(meth, :foo)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123'),
            request_with(:uri => 'http://example.com/search?foo=123')
          )
          expect(matches).to be true
        end

        it 'does not match two requests with different path parts' do
          matches = subject[subject.send(meth, :foo)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123'),
            request_with(:uri => 'http://example.com/find?foo=123')
          )
          expect(matches).to be false
        end

        it 'ignores the given query parameters when it is at the start' do
          matches = subject[subject.send(meth, :foo)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123&bar=r'),
            request_with(:uri => 'http://example.com/search?foo=124&bar=r')
          )
          expect(matches).to be true
        end

        it 'ignores the given query parameters when it is at the end' do
          matches = subject[subject.send(meth, :bar)].matches?(
            request_with(:uri => 'http://example.com/search?foo=124&bar=r'),
            request_with(:uri => 'http://example.com/search?foo=124&bar=q')
          )
          expect(matches).to be true
        end

        it 'still takes into account other query params' do
          matches = subject[subject.send(meth, :bar)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123&bar=r'),
            request_with(:uri => 'http://example.com/search?foo=124&bar=q')
          )
          expect(matches).to be false
        end

        it 'handles multiple query params of the same name' do
          matches = subject[subject.send(meth, :tag)].matches?(
            request_with(:uri => 'http://example.com/search?foo=124&tag[]=a&tag[]=b'),
            request_with(:uri => 'http://example.com/search?foo=124&tag[]=d&tag[]=e')
          )
          expect(matches).to be true
        end

        it 'can ignore multiple named parameters' do
          matches = subject[subject.send(meth, :foo, :bar)].matches?(
            request_with(:uri => 'http://example.com/search?foo=123&bar=r&baz=9'),
            request_with(:uri => 'http://example.com/search?foo=124&baz=9&bar=q')
          )
          expect(matches).to be true
        end

        it 'matches two requests with URIs that have no params' do
          matches = subject[subject.send(meth, :foo, :bar)].matches?(
            request_with(:uri => 'http://example.com/search'),
            request_with(:uri => 'http://example.com/search')
          )
          expect(matches).to be true
        end

        it 'does not match two requests with URIs that have no params but different paths' do
          matches = subject[subject.send(meth, :foo, :bar)].matches?(
            request_with(:uri => 'http://example.com/foo'),
            request_with(:uri => 'http://example.com/bar')
          )
          expect(matches).to be false
        end

        it 'matches a second request when all parameters are filtered' do
          matches = subject[subject.send(meth, :q, :oq)].matches?(
            request_with(:uri => 'http://example.com/search'),
            request_with(:uri => 'http://example.com/search?q=vcr&oq=vcr')
          )
          expect(matches).to be true
        end
      end
    end

    describe "built-ins" do
      describe ":method" do
        it 'matches when it is the same' do
          matches = subject[:method].matches?(
            request_with(:method => :get),
            request_with(:method => :get)
          )
          expect(matches).to be true
        end

        it 'does not match when it is not the same' do
          matches = subject[:method].matches?(
            request_with(:method => :get),
            request_with(:method => :post)
          )
          expect(matches).to be false
        end
      end

      describe ":uri" do
        it 'matches when it is exactly the same' do
          matches = subject[:uri].matches?(
            request_with(:uri => 'http://foo.com/bar?baz=7'),
            request_with(:uri => 'http://foo.com/bar?baz=7')
          )
          expect(matches).to be true
        end

        it 'does not match when it is different' do
          matches = subject[:uri].matches?(
            request_with(:uri => 'http://foo1.com/bar?baz=7'),
            request_with(:uri => 'http://foo2.com/bar?baz=7')
          )
          expect(matches).to be false
        end
      end

      describe ":host" do
        it 'matches when it is the same' do
          matches = subject[:host].matches?(
            request_with(:uri => 'http://foo.com/bar'),
            request_with(:uri => 'http://foo.com/car')
          )
          expect(matches).to be true
        end

        it 'does not match when it is not the same' do
          matches = subject[:host].matches?(
            request_with(:uri => 'http://foo.com/bar'),
            request_with(:uri => 'http://goo.com/bar')
          )
          expect(matches).to be false
        end
      end

      describe ":path" do
        it 'matches when it is the same' do
          matches = subject[:path].matches?(
            request_with(:uri => 'http://foo.com/bar?a=8'),
            request_with(:uri => 'http://goo.com/bar?a=9')
          )
          expect(matches).to be true
        end

        it 'does not match when it is not the same' do
          matches = subject[:path].matches?(
            request_with(:uri => 'http://foo.com/bar?a=8'),
            request_with(:uri => 'http://foo.com/car?a=8')
          )
          expect(matches).to be false
        end
      end

      describe ":body" do
        it 'matches when it is the same' do
          matches = subject[:body].matches?(
            request_with(:body => 'foo'),
            request_with(:body => 'foo')
          )
          expect(matches).to be true
        end

        it 'does not match when it is not the same' do
          matches = subject[:body].matches?(
            request_with(:body => 'foo'),
            request_with(:body => 'bar')
          )
          expect(matches).to be false
        end
      end

      describe ":body_as_json" do
        it 'matches when the body json is reordered' do
          matches = subject[:body_as_json].matches?(
            request_with(:body => '{ "a": "1", "b": "2" }'),
            request_with(:body => '{ "b": "2", "a": "1" }')
          )
          expect(matches).to be true
        end

        it 'does not match when json is not the same' do
          matches = subject[:body_as_json].matches?(
            request_with(:body => '{ "a": "1", "b": "2" }'),
            request_with(:body => '{ "a": "1", "b": "1" }')
          )
          expect(matches).to be false
        end

        it 'does not match when body is not json' do
          matches = subject[:body_as_json].matches?(
            request_with(:body => 'a=b'),
            request_with(:body => 'a=b')
          )
          expect(matches).to be false
        end
      end

      describe ":headers" do
        it 'matches when it is the same' do
          matches = subject[:headers].matches?(
            request_with(:headers => { 'a' => 1, 'b' => 2 }),
            request_with(:headers => { 'b' => 2, 'a' => 1 })
          )
          expect(matches).to be true
        end

        it 'does not match when it is not the same' do
          matches = subject[:headers].matches?(
            request_with(:headers => { 'a' => 3, 'b' => 2 }),
            request_with(:headers => { 'b' => 2, 'a' => 1 })
          )
          expect(matches).to be false
        end
      end

      describe ":query" do
        it 'matches when it is identical' do
          matches = subject[:query].matches?(
            request_with(:uri => 'http://foo.com/bar?a=8'),
            request_with(:uri => 'http://goo.com/car?a=8')
          )
          expect(matches).to be true
        end

        it 'matches when empty' do
          matches = subject[:query].matches?(
            request_with(:uri => 'http://foo.com/bar'),
            request_with(:uri => 'http://goo.com/car')
          )
          expect(matches).to be true
        end

        it 'matches when parameters are reordered' do
          matches = subject[:query].matches?(
            request_with(:uri => 'http://foo.com/bar?a=8&b=9'),
            request_with(:uri => 'http://goo.com/car?b=9&a=8')
          )
          expect(matches).to be true
        end

        it 'does not match when it is not the same' do
          matches = subject[:query].matches?(
            request_with(:uri => 'http://foo.com/bar?a=8'),
            request_with(:uri => 'http://goo.com/car?b=8')
          )
          expect(matches).to be false
        end
      end
    end
  end
end

