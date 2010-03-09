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

  context 'when current_cassette.allow_real_http_requests_to? returns false' do
    before(:each) do
      @current_cassette.should_receive(:allow_real_http_requests_to?).at_least(:once).with(@uri).and_return(false)
    end

    describe 'a request that is not registered with FakeWeb' do
      it 'calls #store_recorded_response! on the current cassette' do
        recorded_response = VCR::RecordedResponse.new(:get, 'http://example.com:80/', :example_response)
        VCR::RecordedResponse.should_receive(:new).with(:get, 'http://example.com:80/', an_instance_of(Net::HTTPOK)).and_return(recorded_response)
        @current_cassette.should_receive(:store_recorded_response!).with(recorded_response)
        Net::HTTP.get(@uri)
      end

      it 'calls #store_recorded_response! only once, even when Net::HTTP internally recursively calls #request' do
        @current_cassette.should_receive(:store_recorded_response!).once
        Net::HTTP.new('example.com', 80).post('/', nil)
      end
    end

    describe 'a request that is registered with FakeWeb' do
      it 'does not call #store_recorded_response! on the current cassette' do
        FakeWeb.register_uri(:get, 'http://example.com', :body => 'example.com response')
        @current_cassette.should_not_receive(:store_recorded_response!)
        Net::HTTP.get(@uri)
      end
    end
  end

  context 'when current_cassette.allow_real_http_requests_to? returns true' do
    before(:each) do
      @current_cassette.should_receive(:allow_real_http_requests_to?).with(@uri).and_return(true)
    end

    it 'does not call #store_recorded_response! on the current cassette' do
      @current_cassette.should_receive(:store_recorded_response!).never
      Net::HTTP.get(@uri)
    end

    it 'uses FakeWeb.with_allow_net_connect_set_to(true) to make the request' do
      FakeWeb.should_receive(:with_allow_net_connect_set_to).with(true).and_yield
      Net::HTTP.get(@uri)
    end
  end
end