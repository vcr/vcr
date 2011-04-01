require 'spec_helper'

describe VCR::RequestMatcher do
  it 'raises an error when given invalid match attributes' do
    expect {
      VCR::RequestMatcher.new(VCR::Request.new, [:not, :valid, :options])
    }.to raise_error(ArgumentError)
  end

  describe '#uri' do
    def self.for_matcher(*attributes, &block)
      context "for match_attributes = #{attributes.inspect}" do
        subject { matcher = VCR::RequestMatcher.new(stub(:uri => uri), attributes).uri }
        module_eval(&block)
      end
    end

    let(:uri) { 'http://foo.example.com/path/to/something?param=value' }

    for_matcher do
      it("returns a regex that matches any URI") { should == /.*/ }
    end

    for_matcher :uri do
      it("returns the exact uri") { should == uri }
    end

    for_matcher :host do
      it("matches a basic URL for the same host") { should =~ 'http://foo.example.com/some/path' }
      it("matches an https URL") { should =~ 'https://foo.example.com/some/path' }
      it("ignores the case of the URL") { should =~ 'HTTP://FOO.EXAMPLE.COM/SOME/PATH' }
      it("matches when the URL has the normal port") { should =~ 'http://foo.example.com:80/some/path' }
      it("matches when the URL has another port") { should =~ 'http://foo.example.com:3750/some/path' }
      it("matches when the URL has a username") { should =~ 'http://someone@foo.example.com/some/path' }
      it("matches when the URL has a username and password") { should =~ 'http://admin:s3cr3t@foo.example.com/some/path' }

      it("does not match when the host is wrong") { should_not =~ 'http://fof.example.com/path/to/something?param=value' }
      it("does not match when the host includes some additional parts")  { should_not =~ 'http://foo.example.com.more.domain.parts/path/to/something?param=value' }
    end

    for_matcher :path do
      it("matches a basic URL for the same path") { should =~ 'http://domain.tld/path/to/something?p=v&q=r' }
      it("matches an https URL") { should =~ 'https://domain.tld/path/to/something?p=v&q=r' }
      it("ignores the case of the URL") { should =~ 'HTTP://DOMAIN.TLD/PATH/TO/SOMETHING?P=V&Q=R' }
      it("matches with a trailing slash") { should =~ 'http://domain.tld/path/to/something/' }
      it("matches without a trailing slash") { should =~ 'http://domain.tld/path/to/something' }
      it("matches when the URL has the normal port") { should =~ 'http://domain.tld:80/path/to/something' }
      it("matches when the URL has another port") { should =~ 'http://domain.tld:3750/path/to/something' }
      it("matches when the URL has a username") { should =~ 'http://someone@domain.tld/path/to/something' }
      it("matches when the URL has a username and password") { should =~ 'http://admin:s3cr3t@domain.tld/path/to/something' }

      it("does not match when the path is wrong") { should_not =~ 'http://foo.example.com/some/other/path?param=value' }
      it("does not match when the path includes some additional parts") { should_not =~ 'http://foo.example.com/path/to/something/else?param=value' }
    end

    for_matcher :host, :path do
      it("matches a basic URL for the same host and path") { should =~ 'http://foo.example.com/path/to/something?p=v' }
      it("matches an https URL") { should =~ 'https://foo.example.com/path/to/something?p=v&q=r' }
      it("ignores the case of the URL") { should =~ 'HTTP://FOO.EXAMPLE.COM/PATH/TO/SOMETHING?P=V&Q=R' }
      it("matches with a trailing slash and some query params") { should =~ 'http://foo.example.com/path/to/something/?p=v&q=r' }
      it("matches with a trailing slash and no query params") { should =~ 'http://foo.example.com/path/to/something/' }
      it("matches without a trailing slash and some query params") { should =~ 'http://foo.example.com/path/to/something?p=v&q=r' }
      it("matches without a trailing slash and no query params") { should =~ 'http://foo.example.com/path/to/something' }
      it("matches when the URL has the normal port") { should =~ 'http://foo.example.com:80/path/to/something?p=v' }
      it("matches when the URL has another port") { should =~ 'http://foo.example.com:3750/path/to/something?p=v' }
      it("matches when the URL has a username") { should =~ 'http://someone@foo.example.com/path/to/something?p=v' }
      it("matches when the URL has a username and password") { should =~ 'http://admin:s3r3t@foo.example.com/path/to/something?p=v' }

      it("does not match when the host is wrong") { should_not =~ 'http://fof.example.com/path/to/something?p=v' }
      it("does not match when the path is wrong") { should_not =~ 'http://foo.example.com/pth/to/something?p=v' }
      it("does not match when the host includes some additional parts") { should_not =~ 'http://foo.example.com.and.more.parts/path/to/something?p=v' }
      it("does not match when the path includes some additional parts") { should_not =~ 'http://foo.example.com/path/to/something/else?p=v' }
    end

    [[:uri, :host], [:uri, :path], [:uri, :host, :path]].each do |attributes|
      for_matcher *attributes do
        it "raises an appropriate error" do
          expect { subject }.to raise_error(/match_attributes cannot include/)
        end
      end
    end

    it "returns the request's URI when it is a regex, regardless of the match attributes" do
      [:uri, :host, :path].each do |attribute|
        matcher = VCR::RequestMatcher.new(stub(:uri => /some regex/), [attribute])
        matcher.uri.should == /some regex/
      end
    end
  end

  describe '#method' do
    it 'returns the request method when the match attributes include :method' do
      matcher = VCR::RequestMatcher.new(stub(:method => :get), [:method])
      matcher.method.should == :get
    end

    it 'returns nil when the match attributes do not include :method' do
      matcher = VCR::RequestMatcher.new(stub(:method => :get), [])
      matcher.method.should be_nil
    end
  end

  describe '#body' do
    it 'returns the request body when the match attributes include :body' do
      matcher = VCR::RequestMatcher.new(stub(:body => 'id=7'), [:body])
      matcher.body.should == 'id=7'
    end

    it 'returns nil when the match attributes do not include :body' do
      matcher = VCR::RequestMatcher.new(stub(:body => 'id=7'), [])
      matcher.method.should be_nil
    end
  end

  describe '#headers' do
    it 'returns the request headers when the match attributes include :headers' do
      matcher = VCR::RequestMatcher.new(stub(:headers => { 'key' => 'value' }), [:headers])
      matcher.headers.should == { 'key' => 'value' }
    end

    it 'returns nil when the match attributes do not include :headers' do
      matcher = VCR::RequestMatcher.new(stub(:headers => { 'key' => 'value' }), [])
      matcher.headers.should be_nil
    end
  end

  def matcher(*different_values)
    match_attributes = [:method, :uri, :body, :headers]
    if different_values.include?(:match_attributes)
      match_attributes -= [:body]
    end

    request_object = different_values.include?(:request) ? 'request2' : 'request'
    m = VCR::RequestMatcher.new(request_object, match_attributes)

    %w( uri method body headers ).each do |attr|
      m.should respond_to(attr)
      m.stub!(attr).and_return(different_values.include?(attr.to_sym) ? attr.next : attr)
    end

    m
  end

  def matchers_varying_on(attribute)
    return matcher, matcher(attribute)
  end

  def matcher_with_headers(headers)
    VCR::RequestMatcher.new(VCR::Request.new(:get, 'http://foo.com/', nil, headers), [:method, :uri, :headers])
  end

  describe '#hash' do
    it 'returns the same code for two objects when #match_attributes, #method, #uri, #body and #headers are the same, even when the request object is different' do
      m1, m2 = matchers_varying_on(:request)
      m1.hash.should == m2.hash
    end

    it 'returns the same code for two objects when the matchers are the same, but #match_attributes has its elements in a different order' do
      m1, m2 = matcher, matcher
      m1.match_attributes = [:method, :uri, :body, :headers]
      m2.match_attributes = [:method, :body, :uri, :headers]
      m1.hash.should == m2.hash
    end

    [:match_attributes, :method, :uri, :body, :headers].each do |different_attr|
      it "returns different codes for two objects when ##{different_attr} is different, even when the request object is the same" do
        m1, m2 = matchers_varying_on(different_attr)
        m1.hash.should_not == m2.hash
      end
    end

    context 'for headers' do
      it 'returns the same code for the same headers' do
        m1 = matcher_with_headers('x-http-header' => ['val1'])
        m2 = matcher_with_headers('x-http-header' => ['val1'])
        m1.hash.should == m2.hash
      end

      it 'returns the same code when the header keys are ordered differently' do
        m1 = matcher_with_headers('x-http-header1' => ['val1'], 'x-http-header2' => ['val2'])
        m2 = matcher_with_headers('x-http-header2' => ['val2'], 'x-http-header1' => ['val1'])
        m1.hash.should == m2.hash
      end

      it 'returns the same code when the header value arrays are ordered differently' do
        m1 = matcher_with_headers('x-http-header' => ['val1', 'val2'])
        m2 = matcher_with_headers('x-http-header' => ['val2', 'val1'])
        m1.hash.should == m2.hash
      end

      it 'returns a different code when the header values are different' do
        m1 = matcher_with_headers('x-http-header' => ['val1'])
        m2 = matcher_with_headers('x-http-header' => ['val2'])
        m1.hash.should_not == m2.hash
      end

      it 'returns a different code when the header keys are different' do
        m1 = matcher_with_headers('x-http-header1' => ['val1'])
        m2 = matcher_with_headers('x-http-header2' => ['val1'])
        m1.hash.should_not == m2.hash
      end
    end
  end

  [:eql?, :==].each do |equality_method|
    describe "##{equality_method.to_s}" do
      it 'returns true when #match_attributes, #method, #uri, #body and #headers are the same, even when the request object is different' do
        m1, m2 = matchers_varying_on(:request)
        m1.send(equality_method, m2).should be_true
        m2.send(equality_method, m1).should be_true
      end

      it 'returns true when the matchers are the same, but #match_attributes has its elements in a different order' do
        m1, m2 = matcher, matcher
        m1.match_attributes = [:method, :uri, :body, :headers]
        m2.match_attributes = [:method, :body, :uri, :headers]
        m1.send(equality_method, m2).should be_true
        m2.send(equality_method, m1).should be_true
      end

      [:match_attributes, :method, :uri, :body, :headers].each do |different_attr|
        it "returns false when ##{different_attr} is different, even when the request object is the same" do
          m1, m2 = matchers_varying_on(different_attr)
          m1.send(equality_method, m2).should be_false
          m2.send(equality_method, m1).should be_false
        end
      end
    end
  end
end
