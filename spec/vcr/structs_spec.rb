require 'yaml'
require 'vcr/structs'

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
end

module VCR
  describe HTTPInteraction do
    %w( uri method ).each do |attr|
      it "delegates :#{attr} to the request signature" do
        sig = mock('request signature')
        sig.should_receive(attr).and_return(:the_value)
        instance = described_class.new(sig, nil)
        instance.send(attr).should eq(:the_value)
      end
    end

    describe '#ignored?' do
      it 'returns false by default' do
        should_not be_ignored
      end

      it 'returns true when #ignore! has been called' do
        subject.ignore!
        should be_ignored
      end
    end

    it 'does not include `@ignored` in the serialized output' do
      subject.ignore!
      YAML.dump(subject).should_not include('ignored')
    end

    describe '#filter!' do
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

      subject { interaction.filter!('foo', 'AAA') }

      it 'does nothing when given a blank argument' do
        expect {
          interaction.filter!(nil, 'AAA')
          interaction.filter!('foo', nil)
          interaction.filter!("", 'AAA')
          interaction.filter!('foo', "")
        }.not_to change { interaction }
      end

      [:request, :response].each do |part|
        it "replaces the sensitive text in the #{part} header keys and values" do
          subject.send(part).headers.should eq({
            'x-http-AAA' => ['bar23', '23AAA'],
            'x-http-bar' => ['AAA23', '18']
          })
        end

        it "replaces the sensitive text in the #{part} body" do
          subject.send(part).body.should eq("The body AAA this is (AAA-Foo)")
        end
      end

      it 'replaces the sensitive text in the response status' do
        subject.response.status.message.should eq('OK AAA')
      end

      it 'replaces sensitive text in the request URI' do
        subject.request.uri.should eq('http://example-AAA.com:80/AAA/')
      end
    end
  end

  describe Request do
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
    end

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
        end
      end
    end
  end
end

