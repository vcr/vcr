require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Net::HTTP Extensions" do
  let(:uri) { URI.parse('http://example.com') }

  describe 'a request that is not registered with the http stubbing adapter' do
    before(:each) do
      VCR.http_stubbing_adapter.should_receive(:request_stubbed?).with(anything, uri).and_return(false)
    end

    def perform_get_with_returning_block
      Net::HTTP.new('example.com', 80).request(Net::HTTP::Get.new('/', {})) do |response|
        return response
      end
    end

    it "does not record headers for which Net::HTTP sets defaults near the end of the real request" do
      VCR.should_receive(:record_http_interaction) do |interaction|
        interaction.request.headers.should_not have_key('content-type')
        interaction.request.headers.should_not have_key('host')
      end
      Net::HTTP.new('example.com', 80).send_request('POST', '/', '', {})
    end

    it "records headers for which Net::HTTP usually sets defaults when the user manually sets their values" do
      VCR.should_receive(:record_http_interaction) do |interaction|
        interaction.request.headers['content-type'].should == ['foo/bar']
        interaction.request.headers['host'].should == ['my-example.com']
      end
      Net::HTTP.new('example.com', 80).send_request('POST', '/', '', { 'Content-Type' => 'foo/bar', 'Host' => 'my-example.com' })
    end

    it 'calls VCR.record_http_interaction' do
      interaction = VCR::HTTPInteraction.new
      VCR::HTTPInteraction.should_receive(:from_net_http_objects).and_return(interaction)
      VCR.should_receive(:record_http_interaction).with(interaction)
      Net::HTTP.get(uri)
    end

    it 'calls #record_http_interaction only once, even when Net::HTTP internally recursively calls #request' do
      VCR.should_receive(:record_http_interaction).once
      Net::HTTP.new('example.com', 80).post('/', nil)
    end

    it 'calls #record_http_interaction when Net::HTTP#request is called with a block with a return statement' do
      VCR.should_receive(:record_http_interaction).once
      perform_get_with_returning_block
    end
  end

  describe 'a request that is registered with the http stubbing adapter' do
    it 'does not call #record_http_interaction on the current cassette' do
      VCR.http_stubbing_adapter.should_receive(:request_stubbed?).with(:get, uri).and_return(true)
      VCR.should_receive(:record_http_interaction).never
      Net::HTTP.get(uri)
    end
  end
end
