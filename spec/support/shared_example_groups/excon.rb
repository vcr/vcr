shared_examples "Excon streaming" do
  context "when Excon's streaming API is used" do
    it 'properly records and plays back the response' do
      VCR.stub(:real_http_connections_allowed? => true)
      recorded, played_back = [1, 2].map do
        chunks = []

        VCR.use_cassette('excon_streaming', :record => :once) do
          Excon.get "http://localhost:#{VCR::SinatraApp.port}/foo", :response_block => lambda { |chunk, remaining_bytes, total_bytes|
            chunks << chunk
          }
        end

        chunks.join
      end

      expect(recorded).to eq(played_back)
      expect(recorded).to eq("FOO!")
    end

    it 'properly records and plays back the response for unexpected status' do
      VCR.stub(:real_http_connections_allowed? => true)
      recorded, played_back = [1, 2].map do
        chunks = []

        VCR.use_cassette('excon_streaming_error', :record => :once) do
          begin
            Excon.get "http://localhost:#{VCR::SinatraApp.port}/404_not_200", :expects => 200, :response_block => lambda { |chunk, remaining_bytes, total_bytes|
              chunks << chunk
            }
          rescue Excon::Errors::Error => e
            chunks << e.response.body
          end
        end

        chunks.join
      end

      expect(recorded).to eq(played_back)
      expect(recorded).to eq('404 not 200')
    end
  end
end

