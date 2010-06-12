require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Net::HTTP Extensions" do
  before(:each) do
    VCR.stub!(:current_cassette).and_return(@current_cassette = mock)
    @uri = URI.parse('http://example.com')
  end

  it 'works when there is no current cassette' do
    VCR.stub!(:current_cassette).and_return(nil)
    lambda { Net::HTTP.get(@uri) }.should_not raise_error
  end

  describe 'a request that is not registered with the http stubbing adapter' do
    before(:each) do
      VCR.http_stubbing_adapter.should_receive(:request_stubbed?).with(anything, 'http://example.com:80/').and_return(false)
    end

    def perform_get_with_returning_block
      Net::HTTP.new('example.com', 80).request(Net::HTTP::Get.new('/', {})) do |response|
        return response
      end
    end

    it 'calls #record_http_interaction on the current cassette' do
      interaction = VCR::HTTPInteraction.new
      VCR::HTTPInteraction.should_receive(:from_net_http_objects).and_return(interaction)
      @current_cassette.should_receive(:record_http_interaction).with(interaction)
      Net::HTTP.get(@uri)
    end

    it 'calls #record_http_interaction only once, even when Net::HTTP internally recursively calls #request' do
      @current_cassette.should_receive(:record_http_interaction).once
      Net::HTTP.new('example.com', 80).post('/', nil)
    end

    it 'calls #record_http_interaction when Net::HTTP#request is called with a block with a return statement' do
      @current_cassette.should_receive(:record_http_interaction).once
      perform_get_with_returning_block
    end
  end

  describe 'a request that is registered with the http stubbing adapter' do
    it 'does not call #record_http_interaction on the current cassette' do
      VCR.http_stubbing_adapter.should_receive(:request_stubbed?).with(:get, 'http://example.com:80/').and_return(true)
      @current_cassette.should_not_receive(:record_http_interaction)
      Net::HTTP.get(@uri)
    end
  end
end