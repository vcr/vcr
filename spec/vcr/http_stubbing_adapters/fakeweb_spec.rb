require 'spec_helper'

describe VCR::HttpStubbingAdapters::FakeWeb, :with_monkey_patches => :fakeweb do
  it_behaves_like 'an http stubbing adapter', 'net/http'

  it_performs('version checking', 'FakeWeb',
    :valid    => %w[ 1.3.0 1.3.1 1.3.99 ],
    :too_low  => %w[ 1.2.8 1.1.30 0.30.30 ],
    :too_high => %w[ 1.4.0 1.10.0 2.0.0 ]
  ) do
    before(:each) { @orig_version = FakeWeb::VERSION }
    after(:each)  { FakeWeb::VERSION = @orig_version }

    # Cannot be regular method def as that raises a "dynamic constant assignment" error
    define_method :stub_version do |version|
      FakeWeb::VERSION = version
    end
  end

  describe "some specific Net::HTTP edge cases" do
    before(:each) do
      VCR.stub(:real_http_connections_allowed? => true)
    end

    it "does not record headers for which Net::HTTP sets defaults near the end of the real request" do
      VCR.should_receive(:record_http_interaction) do |interaction|
        interaction.request.headers.should_not have_key('content-type')
        interaction.request.headers.should_not have_key('host')
      end
      Net::HTTP.new('localhost', VCR::SinatraApp.port).send_request('POST', '/', '', { 'x-http-user' => 'me' })
    end

    it "records headers for which Net::HTTP usually sets defaults when the user manually sets their values" do
      VCR.should_receive(:record_http_interaction) do |interaction|
        interaction.request.headers['content-type'].should eq(['foo/bar'])
        interaction.request.headers['host'].should eq(['my-example.com'])
      end
      Net::HTTP.new('localhost', VCR::SinatraApp.port).send_request('POST', '/', '', { 'Content-Type' => 'foo/bar', 'Host' => 'my-example.com' })
    end

    def perform_get_with_returning_block
      Net::HTTP.new('localhost', VCR::SinatraApp.port).request(Net::HTTP::Get.new('/', {})) do |response|
        return response
      end
    end

    it 'records the interaction when Net::HTTP#request is called with a block with a return statement' do
      VCR.should_receive(:record_http_interaction).once
      perform_get_with_returning_block
    end

    it 'records the interaction only once, even when Net::HTTP internally recursively calls #request' do
      VCR.should_receive(:record_http_interaction).once
      Net::HTTP.new('localhost', VCR::SinatraApp.port).post('/', nil)
    end
  end
end
