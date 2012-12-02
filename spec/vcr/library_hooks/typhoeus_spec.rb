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
      ::WebMock::HttpLibAdapters::TyphoeusAdapter.should_receive(:disable!)
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

      played_back.should eq(recorded)
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
      recorded.should_not be_nil

      played_back.should eq(recorded)
    end
  end
end

