shared_examples_for "an http stubbing adapter" do |supported_http_libraries, supported_request_match_attributes, *other|
  before(:each) { VCR.stub!(:http_stubbing_adapter).and_return(subject) }
  subject { described_class }

  describe '.set_http_connections_allowed_to_default' do
    [true, false].each do |default|
      context "when VCR.configuration.allow_http_connections_when_no_cassette is #{default}" do
        before(:each) { VCR.configuration.allow_http_connections_when_no_cassette = default }

        it "sets http_connections_allowed to #{default}" do
          subject.http_connections_allowed = !default
          expect {
            subject.set_http_connections_allowed_to_default
          }.to change { subject.http_connections_allowed? }.from(!default).to(default)
        end
      end
    end
  end

  describe '.exclusively_enabled' do
    def adapter_enabled?(adapter)
      enabled = nil
      subject.exclusively_enabled { enabled = adapter.enabled? }
      enabled
    end

    VCR::HttpStubbingAdapters::Common.adapters.each do |adapter|
      if adapter == described_class
        it "yields with #{adapter} enabled" do
          adapter_enabled?(adapter).should eq(true)
        end
      else
        it "yields without #{adapter} enabled" do
          adapter_enabled?(adapter).should eq(false)
        end
      end
    end

    it 're-enables all adapters afterwards' do
      VCR::HttpStubbingAdapters::Common.adapters.each { |a| a.should be_enabled }
      subject.exclusively_enabled { }
      VCR::HttpStubbingAdapters::Common.adapters.each { |a| a.should be_enabled }
    end
  end

  if other.include?(:needs_net_http_extension)
    describe '.request_stubbed? using specific match_attributes' do
      let(:interactions) { VCR::YAML.load_file(File.join(VCR::SPEC_ROOT, 'fixtures', 'match_requests_on.yml')) }

      @supported_request_match_attributes = supported_request_match_attributes
      def self.matching_on(attribute, valid1, valid2, invalid, &block)
        supported_request_match_attributes = @supported_request_match_attributes

        describe ":#{attribute}" do
          if supported_request_match_attributes.include?(attribute)
            before(:each) { subject.stub_requests(interactions, [attribute]) }
            module_eval(&block)

            [valid1, valid2].each do |val|
              it "returns true for a #{val.inspect} request" do
                subject.request_stubbed?(request(val), [attribute]).should eq(true)
              end
            end

            it "returns false for another #{attribute}"  do
              subject.request_stubbed?(request(invalid), [attribute]).should eq(false)
            end
          else
            it 'raises an error indicating matching requests on this attribute is not supported' do
              expect { subject.request_stubbed?(VCR::Request.new, [attribute]) }.to raise_error(/does not support matching requests on #{attribute}/)
            end
          end
        end
      end

      matching_on :method, :get, :post, :put do
        def request(http_method)
          VCR::Request.new(http_method, 'http://some-wrong-domain.com/', nil, {})
        end
      end

      matching_on :host, 'example1.com', 'example2.com', 'example3.com' do
        def request(host)
          VCR::Request.new(:get, "http://#{host}/some/wrong/path", nil, {})
        end
      end

      matching_on :uri, 'http://example.com/uri1', 'http://example.com/uri2', 'http://example.com/uri3' do
        def request(uri)
          VCR::Request.new(:get, uri, nil, {})
        end
      end

      matching_on :path, '/path1', '/path2', '/path3' do
        def request(path)
          VCR::Request.new(:get, "http://example.com#{path}", nil, {})
        end
      end

      matching_on :body, 'param=val1', 'param=val2', 'param=val3' do
        def request(body)
          VCR::Request.new(:put, "http://wrong-domain.com/wrong/path", body, {})
        end
      end

      matching_on :headers, { 'X-HTTP-HEADER1' => 'val1' }, { 'X-HTTP-HEADER1' => 'val2' }, { 'X-HTTP-HEADER1' => 'val3' } do
        def request(headers)
          VCR::Request.new(:get, "http://wrong-domain.com/wrong/path", nil, headers)
        end
      end
    end
  end

  supported_http_libraries.each do |library|
    it_behaves_like 'an http library', library, supported_request_match_attributes, *other
  end
end

