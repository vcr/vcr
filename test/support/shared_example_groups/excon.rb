shared_examples "Excon streaming" do
  context "when Excon's streaming API is used" do
    def make_request_to(path)
      chunks = []

      Excon.get "http://localhost:#{VCR::SinatraApp.port}#{path}", :response_block => lambda { |chunk, remaining_bytes, total_bytes|
        chunks << chunk
      }

      chunks.join
    end

    it 'properly records and plays back the response' do
      allow(VCR).to receive(:real_http_connections_allowed?).and_return(true)
      recorded, played_back = [1, 2].map do
        make_request_to('/foo')
      end

      expect(recorded).to eq(played_back)
      expect(recorded).to eq("FOO!")
    end

    it 'properly records and plays back the response for unexpected status' do
      allow(VCR).to receive(:real_http_connections_allowed?).and_return(true)
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

    context "when a cassette is played back and appended to" do
      it 'does not allow Excon to mutate the response body in the cassette' do
        VCR.use_cassette('excon_streaming', :record => :new_episodes) do
          expect(make_request_to('/')).to eq('GET to root')
        end

        VCR.use_cassette('excon_streaming', :record => :new_episodes) do
          expect(make_request_to('/')).to eq('GET to root')
          expect(make_request_to('/foo')).to eq('FOO!') # so it will save to disk again
        end

        VCR.use_cassette('excon_streaming', :record => :new_episodes) do
          expect(make_request_to('/')).to eq('GET to root')
        end
      end
    end
  end
end

