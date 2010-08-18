require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Net::HTTP Extensions" do
  let(:uri) { URI.parse('http://example.com') }

  it 'checks if the request is stubbed using a VCR::Request' do
    VCR.http_stubbing_adapter.should_receive(:request_stubbed?) do |request, _|
      request.uri.should == 'http://example.com:80/'
      request.method.should == :get
      true
    end
    Net::HTTP.get(uri)
  end

  it "checks if the request is stubbed using the current VCR cassette's match_request_on option" do
    VCR.should_receive(:current_cassette).and_return(stub(:match_requests_on => [:body, :header]))
    VCR.http_stubbing_adapter.should_receive(:request_stubbed?).with(anything, [:body, :header]).and_return(true)
    Net::HTTP.get(uri)
  end

  it "checks if the request is stubbed using the default match attributes when there is no current cassette" do
    VCR.should_receive(:current_cassette).and_return(nil)
    VCR.http_stubbing_adapter.should_receive(:request_stubbed?).with(anything, VCR::RequestMatcher::DEFAULT_MATCH_ATTRIBUTES).and_return(true)
    Net::HTTP.get(uri)
  end

  describe 'a request that is not registered with the http stubbing adapter' do
    before(:each) do
      VCR.http_stubbing_adapter.stub(:request_stubbed?).and_return(false)
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
      VCR.should_receive(:record_http_interaction).with(instance_of(VCR::HTTPInteraction))
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
      VCR.http_stubbing_adapter.stub(:request_stubbed?).and_return(true)
      VCR.should_receive(:record_http_interaction).never
      Net::HTTP.get(uri)
    end
  end
end
