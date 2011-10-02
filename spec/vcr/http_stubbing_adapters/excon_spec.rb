require 'spec_helper'

describe "Excon adapter" do
  it_behaves_like 'an http stubbing adapter', 'excon', :status_message_not_exposed

  it_performs('version checking', 'Excon',
    :valid    => %w[ 0.6.5 0.6.99 ],
    :too_low  => %w[ 0.5.99 0.6.4 ],
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
      VCR.stub(:real_http_connections_allowed? => true)
      recorded, played_back = [1, 2].map do
        VCR.use_cassette('excon_query', :record => :once) do
          excon.request(:method => :get, :query => { :q => 'Tolkien' }).body
        end
      end

      recorded.should eq(played_back)
      recorded.should eq('query: Tolkien')
    end
  end

  context "when Excon's streaming API is used" do
    it 'properly records and plays back the response' do
      VCR.stub(:real_http_connections_allowed? => true)
      recorded, played_back = [1, 2].map do
        chunks = []

        VCR.use_cassette('excon_streaming', :record => :once) do
          Excon.get("http://localhost:#{VCR::SinatraApp.port}/foo") do |chunk, remaining_bytes, total_bytes|
            chunks << chunk
          end
        end

        chunks.join
      end

      recorded.should eq(played_back)
      recorded.should eq("FOO!")
    end
  end

  context 'when Excon raises an error due to an unexpected response status' do
    it 'still records properly' do
      VCR.stub(:real_http_connections_allowed? => true)

      VCR.should_receive(:record_http_interaction) do |interaction|
        interaction.response.status.code.should eq(404)
      end

      expect {
        Excon.get("http://localhost:#{VCR::SinatraApp.port}/not_found", :expects => 200)
      }.to raise_error(Excon::Errors::Error)
    end
  end
end

