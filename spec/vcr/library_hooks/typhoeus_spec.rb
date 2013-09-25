require 'spec_helper'

describe "Typhoeus hook", :with_monkey_patches => :typhoeus do
  after(:each) do
    ::Typhoeus::Expectation.clear
  end

  def disable_real_connections
    ::Typhoeus::Config.block_connection = true
    ::Typhoeus::Errors::NoStub
  end

  def enable_real_connections
    ::Typhoeus::Config.block_connection = false
  end

  def directly_stub_request(method, url, response_body)
    response = ::Typhoeus::Response.new(:code => 200, :body => response_body)
    ::Typhoeus.stub(url, :method => method).and_return(response)
  end

  it_behaves_like 'a hook into an HTTP library', :typhoeus, 'typhoeus'

  describe "VCR.configuration.after_library_hooks_loaded hook" do
    it 'disables the webmock typhoeus adapter so it does not conflict with our typhoeus hook' do
      expect(::WebMock::HttpLibAdapters::TyphoeusAdapter).to receive(:disable!)
      $typhoeus_after_loaded_hook.conditionally_invoke
    end
  end

  context 'when there are nested hydra queues' do
    def make_requests
      VCR.use_cassette("nested") do
        response_1 = response_2 = nil

        hydra   = Typhoeus::Hydra.new
        request = Typhoeus::Request.new("http://localhost:#{VCR::SinatraApp.port}/")

        request.on_success do |r1|
          response_1 = r1

          nested = Typhoeus::Request.new("http://localhost:#{VCR::SinatraApp.port}/foo")
          nested.on_success { |r2| response_2 = r2 }

          hydra.queue(nested)
        end

        hydra.queue(request)
        hydra.run

        return body_for(response_1), body_for(response_2)
      end
    end

    def body_for(response)
      return :no_response if response.nil?
      response.body
    end

    it 'records and plays back properly' do
      recorded = make_requests
      played_back = make_requests

      expect(played_back).to eq(recorded)
    end
  end

  context "when used with a typhoeus-based faraday connection" do
    let(:base_url) { "http://localhost:#{VCR::SinatraApp.port}" }

    let(:conn) do
      Faraday.new(:url => base_url) do |faraday|
        faraday.adapter  :typhoeus
      end
    end

    def get_response
      # Ensure faraday hook doesn't handle the request.
      VCR.library_hooks.exclusively_enabled(:typhoeus) do
        VCR.use_cassette("faraday") do
          conn.get("/")
        end
      end
    end

    it 'records and replays headers correctly' do
      pending "waiting on typhoeus/typhoeus#324" do
        recorded = get_response
        played_back = get_response

        expect(played_back.headers).to eq(recorded.headers)
      end
    end
  end

  context '#effective_url' do
    def make_single_request
      VCR.use_cassette('single') do
        response = Typhoeus::Request.new("http://localhost:#{VCR::SinatraApp.port}/").run

        response.effective_url
      end
    end

    it 'recorded and played back properly' do
      recorded = make_single_request
      played_back = make_single_request
      expect(recorded).not_to be_nil

      expect(played_back).to eq(recorded)
    end
  end
end

