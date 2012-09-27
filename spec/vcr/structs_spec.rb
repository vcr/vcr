# encoding: UTF-8

require 'support/ruby_interpreter'

require 'yaml'
require 'vcr/structs'
require 'vcr/errors'
require 'zlib'
require 'stringio'
require 'support/limited_uri'

shared_examples_for "a header normalizer" do
  let(:instance) do
    with_headers('Some_Header' => 'value1', 'aNother' => ['a', 'b'], 'third' => [], 'fourth' => nil)
  end

  it 'ensures header keys are serialized to yaml as raw strings' do
    key = 'my-key'
    key.instance_variable_set(:@foo, 7)
    instance = with_headers(key => ['value1'])
    YAML.dump(instance.headers).should eq(YAML.dump('my-key' => ['value1']))
  end

  it 'ensures header values are serialized to yaml as raw strings' do
    value = 'my-value'
    value.instance_variable_set(:@foo, 7)
    instance = with_headers('my-key' => [value])
    YAML.dump(instance.headers).should eq(YAML.dump('my-key' => ['my-value']))
  end

  it 'handles nested arrays' do
    accept_encoding = [["gzip", "1.0"], ["deflate", "1.0"], ["sdch", "1.0"]]
    instance = with_headers('accept-encoding' => accept_encoding)
    instance.headers['accept-encoding'].should eq(accept_encoding)
  end

  it 'handles nested arrays with floats' do
    accept_encoding = [["gzip", 1.0], ["deflate", 1.0], ["sdch", 1.0]]
    instance = with_headers('accept-encoding' => accept_encoding)
    instance.headers['accept-encoding'].should eq(accept_encoding)
  end
end

shared_examples_for "a body normalizer" do
  it "ensures the body is serialized to yaml as a raw string" do
    body = "My String"
    body.instance_variable_set(:@foo, 7)
    YAML.dump(instance(body).body).should eq(YAML.dump("My String"))
  end

  it 'converts nil to a blank string' do
    instance(nil).body.should eq("")
  end

  it 'raises an error if given another type of object as the body' do
    expect {
      instance(:a => "hash")
    }.to raise_error(ArgumentError)
  end
end

module VCR
  describe HTTPInteraction do
    before { VCR.stub_chain(:configuration, :uri_parser) { LimitedURI } }

    if ''.respond_to?(:encoding)
      def body_hash(key, value)
        { key => value, 'encoding' => 'UTF-8' }
      end
    else
      def body_hash(key, value)
        { key => value }
      end
    end

    describe "#recorded_at" do
      let(:now) { Time.now }

      it 'is initialized to the current time' do
        Time.stub(:now => now)
        VCR::HTTPInteraction.new.recorded_at.should eq(now)
      end
    end

    let(:status)      { ResponseStatus.new(200, "OK") }
    let(:response)    { Response.new(status, { "foo" => ["bar"] }, "res body", "1.1") }
    let(:request)     { Request.new(:get, "http://foo.com/", "req body", { "bar" => ["foo"] }) }
    let(:recorded_at) { Time.utc(2011, 5, 4, 12, 30) }
    let(:interaction) { HTTPInteraction.new(request, response, recorded_at) }

    describe ".from_hash" do
      let(:hash) do
        {
          'request' => {
            'method'  => 'get',
            'uri'     => 'http://foo.com/',
            'body'    => body_hash('string', 'req body'),
            'headers' => { "bar" => ["foo"] }
          },
          'response' => {
            'status'       => {
              'code'       => 200,
              'message'    => 'OK'
            },
            'headers'      => { "foo"     => ["bar"] },
            'body'         => body_hash('string', 'res body'),
            'http_version' => '1.1'
          },
          'recorded_at' => "Wed, 04 May 2011 12:30:00 GMT"
        }
      end

      it 'constructs an HTTP interaction from the given hash' do
        HTTPInteraction.from_hash(hash).should eq(interaction)
      end

      it 'initializes the recorded_at timestamp from the hash' do
        HTTPInteraction.from_hash(hash).recorded_at.should eq(recorded_at)
      end

      it 'uses a blank request when the hash lacks one' do
        hash.delete('request')
        i = HTTPInteraction.from_hash(hash)
        i.request.should eq(Request.new)
      end

      it 'uses a blank response when the hash lacks one' do
        hash.delete('response')
        i = HTTPInteraction.from_hash(hash)
        i.response.should eq(Response.new(ResponseStatus.new))
      end

      it 'decodes the base64 body string' do
        hash['request']['body'] = body_hash('base64_string', Base64.encode64('req body'))
        hash['response']['body'] = body_hash('base64_string', Base64.encode64('res body'))

        i = HTTPInteraction.from_hash(hash)
        i.request.body.should eq('req body')
        i.response.body.should eq('res body')
      end

      if ''.respond_to?(:encoding)
        it 'force encodes the decoded base64 string as the original encoding' do
          string = "café"
          string.force_encoding("US-ASCII")
          string.should_not be_valid_encoding

          hash['request']['body']  = { 'base64_string' => Base64.encode64(string.dup), 'encoding' => 'US-ASCII' }
          hash['response']['body'] = { 'base64_string' => Base64.encode64(string.dup), 'encoding' => 'US-ASCII' }

          i = HTTPInteraction.from_hash(hash)
          i.request.body.encoding.name.should eq("US-ASCII")
          i.response.body.encoding.name.should eq("US-ASCII")
          i.request.body.bytes.to_a.should eq(string.bytes.to_a)
          i.response.body.bytes.to_a.should eq(string.bytes.to_a)
          i.request.body.should_not be_valid_encoding
          i.response.body.should_not be_valid_encoding
        end

        it 'does not attempt to force encode the decoded base64 string when there is no encoding given (i.e. if the cassette was recorded on ruby 1.8)' do
          hash['request']['body']  = { 'base64_string' => Base64.encode64('foo') }

          i = HTTPInteraction.from_hash(hash)
          i.request.body.should eq('foo')
          i.request.body.encoding.name.should eq("ASCII-8BIT")
        end

        it 'tries to encode strings to the original encoding' do
          hash['request']['body']  = { 'string' => "abc", 'encoding' => 'ISO-8859-1' }
          hash['response']['body'] = { 'string' => "abc", 'encoding' => 'ISO-8859-1' }

          i = HTTPInteraction.from_hash(hash)
          i.request.body.should eq("abc")
          i.response.body.should eq("abc")
          i.request.body.encoding.name.should eq("ISO-8859-1")
          i.response.body.encoding.name.should eq("ISO-8859-1")
        end

        it 'does not attempt to encode the string when there is no encoding given (i.e. if the cassette was recorded on ruby 1.8)' do
          string = 'foo'
          string.force_encoding("ISO-8859-1")
          hash['request']['body']  = { 'string' => string }

          i = HTTPInteraction.from_hash(hash)
          i.request.body.should eq('foo')
          i.request.body.encoding.name.should eq("ISO-8859-1")
        end

        it 'force encodes to ASCII-8BIT (since it just means "no encoding" or binary)' do
          string = "\u00f6"
          string.encode("UTF-8")
          string.should be_valid_encoding
          hash['request']['body']  = { 'string' => string, 'encoding' => 'ASCII-8BIT' }

          Request.should_not_receive(:warn)
          i = HTTPInteraction.from_hash(hash)
          i.request.body.should eq(string)
          i.request.body.bytes.to_a.should eq(string.bytes.to_a)
          i.request.body.encoding.name.should eq("ASCII-8BIT")
        end

        context 'when the string cannot be encoded as the original encoding' do
          def verify_encoding_error
            pending "rubinius 1.9 mode does not raise an encoding error", :if => (RUBY_INTERPRETER == :rubinius && RUBY_VERSION =~ /^1.9/) do
              expect { "\xFAbc".encode("ISO-8859-1") }.to raise_error(EncodingError)
            end
          end

          before do
            Request.stub(:warn)
            Response.stub(:warn)

            hash['request']['body']  = { 'string' => "\xFAbc", 'encoding' => 'ISO-8859-1' }
            hash['response']['body']  = { 'string' => "\xFAbc", 'encoding' => 'ISO-8859-1' }

            verify_encoding_error
          end

          it 'does not force the encoding' do
            i = HTTPInteraction.from_hash(hash)
            i.request.body.should eq("\xFAbc")
            i.response.body.should eq("\xFAbc")
            i.request.body.encoding.name.should_not eq("ISO-8859-1")
            i.response.body.encoding.name.should_not eq("ISO-8859-1")
          end

          it 'prints a warning and informs users of the :preserve_exact_body_bytes option' do
            Request.should_receive(:warn).with(/ISO-8859-1.*preserve_exact_body_bytes/)
            Response.should_receive(:warn).with(/ISO-8859-1.*preserve_exact_body_bytes/)

            HTTPInteraction.from_hash(hash)
          end
        end
      end
    end

    describe "#to_hash" do
      before(:each) do
        VCR.stub_chain(:configuration, :preserve_exact_body_bytes_for?).and_return(false)
        VCR.stub_chain(:configuration, :uri_parser).and_return(URI)
      end

      let(:hash) { interaction.to_hash }

      it 'returns a nested hash containing all of the pertinent details' do
        hash.keys.should =~ %w[ request response recorded_at ]

        hash['recorded_at'].should eq(interaction.recorded_at.httpdate)

        hash['request'].should eq({
          'method'  => 'get',
          'uri'     => 'http://foo.com/',
          'body'    => body_hash('string', 'req body'),
          'headers' => { "bar" => ["foo"] }
        })

        hash['response'].should eq({
          'status'       => {
            'code'       => 200,
            'message'    => 'OK'
          },
          'headers'      => { "foo"     => ["bar"] },
          'body'         => body_hash('string', 'res body'),
          'http_version' => '1.1'
        })
      end

      it 'encodes the body as base64 when the configuration is so set' do
        VCR.stub_chain(:configuration, :preserve_exact_body_bytes_for?).and_return(true)
        hash['request']['body'].should eq(body_hash('base64_string', Base64.encode64('req body')))
        hash['response']['body'].should eq(body_hash('base64_string', Base64.encode64('res body')))
      end

      it "sets the string's original encoding", :if => ''.respond_to?(:encoding) do
        interaction.request.body.force_encoding('ISO-8859-10')
        interaction.response.body.force_encoding('ASCII-8BIT')

        hash['request']['body']['encoding'].should eq('ISO-8859-10')
        hash['response']['body']['encoding'].should eq('ASCII-8BIT')
      end

      def assert_yielded_keys(hash, *keys)
        yielded_keys = []
        hash.each { |k, v| yielded_keys << k }
        yielded_keys.should eq(keys)
      end

      it 'yields the entries in the expected order so the hash can be serialized in that order' do
        assert_yielded_keys hash, 'request', 'response', 'recorded_at'
        assert_yielded_keys hash['request'], 'method', 'uri', 'body', 'headers'
        assert_yielded_keys hash['response'], 'status', 'headers', 'body', 'http_version'
        assert_yielded_keys hash['response']['status'], 'code', 'message'
      end
    end

    describe "#parsed_uri" do
      before :each do
        uri_parser.stub(:parse).and_return(uri)
        VCR.stub_chain(:configuration, :uri_parser).and_return(uri_parser)
      end

      let(:uri_parser){ mock('parser') }
      let(:uri){ mock('uri').as_null_object }

      it "parses the uri using the current uri_parser" do
        uri_parser.should_receive(:parse).with(request.uri)
        request.parsed_uri
      end

      it "returns the parsed uri" do
        request.parsed_uri.should == uri
      end
    end
  end

  describe HTTPInteraction::HookAware do
    before { VCR.stub_chain(:configuration, :uri_parser) { LimitedURI } }

    let(:response_status) { VCR::ResponseStatus.new(200, "OK foo") }
    let(:body) { "The body foo this is (foo-Foo)" }
    let(:headers) do {
      'x-http-foo' => ['bar23', '23foo'],
      'x-http-bar' => ['foo23', '18']
    } end

    let(:response) do
      VCR::Response.new(
        response_status,
        headers.dup,
        body.dup,
        '1.1'
      )
    end

    let(:request) do
      VCR::Request.new(
        :get,
        'http://example-foo.com:80/foo/',
        body.dup,
        headers.dup
      )
    end

    let(:interaction) { VCR::HTTPInteraction.new(request, response) }
    subject { HTTPInteraction::HookAware.new(interaction) }

    describe '#ignored?' do
      it 'returns false by default' do
        should_not be_ignored
      end

      it 'returns true when #ignore! has been called' do
        subject.ignore!
        should be_ignored
      end
    end

    describe '#filter!' do
      let(:filtered) { subject.filter!('foo', 'AAA') }

      it 'does nothing when given a blank argument' do
        expect {
          subject.filter!(nil, 'AAA')
          subject.filter!('foo', nil)
          subject.filter!("", 'AAA')
          subject.filter!('foo', "")
        }.not_to change { interaction }
      end

      [:request, :response].each do |part|
        it "replaces the sensitive text in the #{part} header keys and values" do
          filtered.send(part).headers.should eq({
            'x-http-AAA' => ['bar23', '23AAA'],
            'x-http-bar' => ['AAA23', '18']
          })
        end

        it "replaces the sensitive text in the #{part} body" do
          filtered.send(part).body.should eq("The body AAA this is (AAA-Foo)")
        end
      end

      it 'replaces the sensitive text in the response status' do
        filtered.response.status.message.should eq('OK AAA')
      end

      it 'replaces sensitive text in the request URI' do
        filtered.request.uri.should eq('http://example-AAA.com/AAA/')
      end

      it 'handles numbers (such as the port) properly' do
        request.uri = "http://foo.com:9000/bar"
        subject.filter!(9000, "<PORT>")
        request.uri.should eq("http://foo.com:<PORT>/bar")
      end
    end
  end

  describe Request::Typed do
    [:uri, :method, :headers, :body].each do |method|
      it "delegates ##{method} to the request" do
        request = stub(method => "delegated value")
        Request::Typed.new(request, :type).send(method).should eq("delegated value")
      end
    end

    describe "#type" do
      it 'returns the initialized type' do
        Request::Typed.new(stub, :ignored).type.should be(:ignored)
      end
    end

    valid_types = [:ignored, :stubbed_by_vcr, :externally_stubbed, :recordable, :unhandled]
    valid_types.each do |type|
      describe "##{type}?" do
        it "returns true if the type is set to :#{type}" do
          Request::Typed.new(stub, type).send("#{type}?").should be_true
        end

        it "returns false if the type is set to :other" do
          Request::Typed.new(stub, :other).send("#{type}?").should be_false
        end
      end
    end

    describe "#real?" do
      real_types = [:ignored, :recordable]
      real_types.each do |type|
        it "returns true if the type is set to :#{type}" do
          Request::Typed.new(stub, type).should be_real
        end
      end

      (valid_types - real_types).each do |type|
        it "returns false if the type is set to :#{type}" do
          Request::Typed.new(stub, type).should_not be_real
        end
      end
    end

    describe "#stubbed?" do
      stubbed_types = [:externally_stubbed, :stubbed_by_vcr]
      stubbed_types.each do |type|
        it "returns true if the type is set to :#{type}" do
          Request::Typed.new(stub, type).should be_stubbed
        end
      end

      (valid_types - stubbed_types).each do |type|
        it "returns false if the type is set to :#{type}" do
          Request::Typed.new(stub, type).should_not be_stubbed
        end
      end
    end
  end

  describe Request do
    before { VCR.stub_chain(:configuration, :uri_parser) { LimitedURI } }

    describe '#method' do
      subject { VCR::Request.new(:get) }

      context 'when given no arguments' do
        it 'returns the HTTP method' do
          subject.method.should eq(:get)
        end
      end

      context 'when given an argument' do
        it 'returns the method object for the named method' do
          m = subject.method(:class)
          m.should be_a(Method)
          m.call.should eq(described_class)
        end
      end

      it 'gets normalized to a lowercase symbol' do
        VCR::Request.new("GET").method.should eq(:get)
        VCR::Request.new(:GET).method.should eq(:get)
        VCR::Request.new(:get).method.should eq(:get)
        VCR::Request.new("get").method.should eq(:get)
      end
    end

    describe "#uri" do
      def uri_for(uri)
        VCR::Request.new(:get, uri).uri
      end

      it 'removes the default http port' do
        uri_for("http://foo.com:80/bar").should eq("http://foo.com/bar")
      end

      it 'removes the default https port' do
        uri_for("https://foo.com:443/bar").should eq("https://foo.com/bar")
      end

      it 'does not remove a non-standard http port' do
        uri_for("http://foo.com:81/bar").should eq("http://foo.com:81/bar")
      end

      it 'does not remove a non-standard https port' do
        uri_for("https://foo.com:442/bar").should eq("https://foo.com:442/bar")
      end
    end

    describe Request::FiberAware do
      subject { Request::FiberAware.new(Request.new) }

      it 'adds a #proceed method that yields in a fiber' do
        fiber = Fiber.new do |request|
          request.proceed
          :done
        end

        fiber.resume(subject).should be_nil
        fiber.resume.should eq(:done)
      end

      it 'can be cast to a proc' do
        Fiber.should_receive(:yield)
        lambda(&subject).call
      end
    end if RUBY_VERSION > '1.9'

    it_behaves_like 'a header normalizer' do
      def with_headers(headers)
        described_class.new(:get, 'http://example.com/', nil, headers)
      end
    end

    it_behaves_like 'a body normalizer' do
      def instance(body)
        described_class.new(:get, 'http://example.com/', body, {})
      end
    end
  end

  describe Response do
    it_behaves_like 'a header normalizer' do
      def with_headers(headers)
        described_class.new(:status, headers, nil, '1.1')
      end
    end

    it_behaves_like 'a body normalizer' do
      def instance(body)
        described_class.new(:status, {}, body, '1.1')
      end
    end

    describe '#update_content_length_header' do
      %w[ content-length Content-Length ].each do |header|
        context "for the #{header} header" do
          define_method :instance do |body, content_length|
            headers = { 'content-type' => 'text' }
            headers.merge!(header => content_length) if content_length
            described_class.new(VCR::ResponseStatus.new, headers, body)
          end

          it 'does nothing when the response lacks a content_length header' do
            inst = instance('the body', nil)
            expect {
              inst.update_content_length_header
            }.not_to change { inst.headers[header] }
          end

          it 'sets the content_length header to the response body length when the header is present' do
            inst = instance('the body', '3')
            expect {
              inst.update_content_length_header
            }.to change { inst.headers[header] }.from(['3']).to(['8'])
          end

          it 'sets the content_length header to 0 if the response body is nil' do
            inst = instance(nil, '3')
            expect {
              inst.update_content_length_header
            }.to change { inst.headers[header] }.from(['3']).to(['0'])
          end

          it 'sets the header according to RFC 2616 based on the number of bytes (not the number of characters)' do
            inst = instance('aؼ', '2') # the second char is a double byte char
            expect {
              inst.update_content_length_header
            }.to change { inst.headers[header] }.from(['2']).to(['3'])
          end
        end
      end
    end

    describe '#decompress' do
      %w[ content-encoding Content-Encoding ].each do |header|
        context "for the #{header} header" do
          define_method :instance do |body, content_encoding|
            headers = { 'content-type' => 'text',
                        'content-length' => body.bytesize.to_s }
            headers[header] = content_encoding if content_encoding
            described_class.new(VCR::ResponseStatus.new, headers, body)
          end

          let(:content) { 'The quick brown fox jumps over the lazy dog' }

          it "does nothing when no compression" do
            resp = instance('Hello', nil)
            resp.should_not be_compressed
            expect {
              resp.decompress.should equal(resp)
            }.to_not change { resp.headers['content-length'] }
          end

          it "does nothing when encoding is 'identity'" do
            resp = instance('Hello', 'identity')
            resp.should_not be_compressed
            expect {
              resp.decompress.should equal(resp)
            }.to_not change { resp.headers['content-length'] }
          end

          it "raises error for unrecognized encoding" do
            resp = instance('Hello', 'flabbergaster')
            resp.should_not be_compressed
            expect { resp.decompress }.
              to raise_error(Errors::UnknownContentEncodingError, 'unknown content encoding: flabbergaster')
          end

          it "unzips gzipped response" do
            pending "rubinius 1.9 mode has a Gzip issue", :if => (RUBY_INTERPRETER == :rubinius && RUBY_VERSION =~ /^1.9/) do
              io = StringIO.new

              writer = Zlib::GzipWriter.new(io)
              writer << content
              writer.close

              gzipped = io.string
              resp = instance(gzipped, 'gzip')
              resp.should be_compressed
              expect {
                resp.decompress.should equal(resp)
                resp.should_not be_compressed
                resp.body.should eq(content)
              }.to change { resp.headers['content-length'] }.
                from([gzipped.bytesize.to_s]).
                to([content.bytesize.to_s])
            end
          end

          it "inflates deflated response" do
            deflated = Zlib::Deflate.deflate(content)
            resp = instance(deflated, 'deflate')
            resp.should be_compressed
            expect {
              resp.decompress.should equal(resp)
              resp.should_not be_compressed
              resp.body.should eq(content)
            }.to change { resp.headers['content-length'] }.
              from([deflated.bytesize.to_s]).
              to([content.bytesize.to_s])
          end
        end
      end
    end
  end
end

