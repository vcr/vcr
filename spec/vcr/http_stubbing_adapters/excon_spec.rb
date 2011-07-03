require 'spec_helper'

describe VCR::HttpStubbingAdapters::Excon, :without_monkey_patches => :vcr do
  it_behaves_like 'an http stubbing adapter',
    ['excon'],
    [:method, :uri, :host, :path, :body, :headers],
    :status_message_not_exposed

  it_performs('version checking',
    :valid    => %w[ 0.6.2 0.6.99 ],
    :too_low  => %w[ 0.5.99 0.6.1 ],
    :too_high => %w[ 0.7.0 1.0.0 ]
  ) do
    before(:each) { @orig_version = Excon::VERSION }
    after(:each)  { Excon::VERSION = @orig_version }

    # Cannot be regular method def as that raises a "dynamic constant assignment" error
    define_method :stub_version do |version|
      Excon::VERSION = version
    end
  end

  context "when the query is specified as a hash option" do
    let(:excon) { ::Excon.new("http://localhost:#{VCR::SinatraApp.port}/search") }

    it 'properly records and plays back the response' do
      described_class.http_connections_allowed = true
      recorded, played_back = [1, 2].map do
        VCR.use_cassette('excon_query', :record => :once) do
          excon.request(:method => :get, :query => { :q => 'Tolkien' }).body
        end
      end

      recorded.should == played_back
      recorded.should == 'query: Tolkien'
    end
  end
end

