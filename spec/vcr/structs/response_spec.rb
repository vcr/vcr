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
