require 'spec_helper'

describe VCR::Response do
  it_performs 'header normalization' do
    def with_headers(headers)
      described_class.new(:status, headers, nil, '1.1')
    end
  end

  it_performs 'body normalization' do
    def instance(body)
      described_class.new(:status, {}, body, '1.1')
    end
  end

  describe '#update_content_length_header' do
    def instance(body, content_length = nil)
      headers = { 'content-type' => 'text' }
      headers.merge!('content-length' => content_length) if content_length
      described_class.new(VCR::ResponseStatus.new, headers, body)
    end

    it 'does nothing when the response lacks a content_length header' do
      inst = instance('the body')
      expect {
        inst.update_content_length_header
      }.not_to change { inst.headers['content-length'] }
    end

    it 'sets the content_length header to the response body length when the header is present' do
      inst = instance('the body', '3')
      expect {
        inst.update_content_length_header
      }.to change { inst.headers['content-length'] }.from(['3']).to(['8'])
    end

    it 'sets the content_length header to 0 if the response body is nil' do
      inst = instance(nil, '3')
      expect {
        inst.update_content_length_header
      }.to change { inst.headers['content-length'] }.from(['3']).to(['0'])
    end
  end
end
