require 'spec_helper'

describe VCR::Response do
  describe '.from_net_http_response' do
    let(:response) { VCR::YAML.load_file("#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/example_net_http_response.yml") }
    subject { described_class.from_net_http_response(response) }

    it                 { should be_instance_of(described_class) }
    its(:body)         { should == 'The response from example.com' }
    its(:http_version) { should == '1.1' }
    its(:headers)      { should == {
      "last-modified"  => ['Tue, 15 Nov 2005 13:24:10 GMT'],
      "etag"           => ["\"24ec5-1b6-4059a80bfd280\""],
      "content-type"   => ["text/html; charset=UTF-8"],
      "date"           => ['Wed, 31 Mar 2010 02:43:26 GMT'],
      "server"         => ['Apache/2.2.3 (CentOS)'],
      "content-length" => ['438'],
      "accept-ranges"  => ['bytes']
    } }

    it 'assigns the status using VCR::ResponseStatus.from_net_http_response' do
      VCR::ResponseStatus.should respond_to(:from_net_http_response)
      VCR::ResponseStatus.should_receive(:from_net_http_response).with(response).and_return(:the_status)
      subject.status.should == :the_status
    end
  end

  it_performs 'header normalization' do
    def with_headers(headers)
      described_class.new(:status, headers, nil, '1.1')
    end
  end

  it_performs 'body normalization' do
    def instance(body)
      described_class.new(:status, {}, body, body.encoding.to_s, '1.1')
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
  end
end
