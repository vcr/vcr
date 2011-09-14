require 'spec_helper'

describe VCR::Request do
  describe '#matcher' do
    it 'returns a matcher with the given request' do
      req = VCR::Request.new
      req.matcher([:uri]).request.should eq(req)
    end

    it 'returns a matcher with the given match_attributes' do
      req = VCR::Request.new
      req.matcher([:uri, :headers]).match_attributes.to_a.should =~ [:uri, :headers]
    end
  end

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

  it_performs 'uri normalization' do
    def instance(uri)
      VCR::Request.new(:get, uri, '', {})
    end
  end

  it_performs 'header normalization' do
    def with_headers(headers)
      described_class.new(:get, 'http://example.com/', nil, headers)
    end
  end

  it_performs 'body normalization' do
    def instance(body)
      described_class.new(:get, 'http://example.com/', body, {})
    end
  end
end
