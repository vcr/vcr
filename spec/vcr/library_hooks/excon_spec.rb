require 'spec_helper'
require 'support/shared_example_groups/excon'

describe "Excon hook", :with_monkey_patches => :excon do
  # TODO: figure out a way to get disabling VCR to work with Excon
  #       and allow dirct excon stubs to work.
  # def directly_stub_request(method, url, response_body)
  #   ::Excon.stub({ :method => method, :url => url }, { :body => response_body })
  # end

  it_behaves_like 'a hook into an HTTP library', :excon, 'excon', :status_message_not_exposed

  context "when the query is specified as a hash option" do
    let(:excon) { ::Excon.new("http://localhost:#{VCR::SinatraApp.port}/search") }

    it 'properly records and plays back the response' do
      VCR.stub(:real_http_connections_allowed? => true)
      recorded, played_back = [1, 2].map do
        VCR.use_cassette('excon_query', :record => :once) do
          excon.request(:method => :get, :query => { :q => 'Tolkien' }).body
        end
      end

      expect(recorded).to eq(played_back)
      expect(recorded).to eq('query: Tolkien')
    end
  end

  include_examples "Excon streaming"

  context 'when Excon raises an error due to an unexpected response status' do
    before(:each) do
      VCR.stub(:real_http_connections_allowed? => true)
    end

    it 'still records properly' do
      VCR.should_receive(:record_http_interaction) do |interaction|
        expect(interaction.response.status.code).to eq(404)
      end

      expect {
        Excon.get("http://localhost:#{VCR::SinatraApp.port}/not_found", :expects => 200)
      }.to raise_error(Excon::Errors::Error)
    end

    def error_raised_by
      yield
    rescue => e
      return e
    else
      raise "No error was raised"
    end

    it 'raises the same error class as excon itself raises' do
      real_error, stubbed_error = 2.times.map do
        error_raised_by do
          VCR.use_cassette('excon_error', :record => :once) do
            Excon.get("http://localhost:#{VCR::SinatraApp.port}/not_found", :expects => 200)
          end
        end
      end

      expect(stubbed_error.class).to be(real_error.class)
    end

    it_behaves_like "request hooks", :excon, :recordable do
      undef make_request
      def make_request(disabled = false)
        expect {
          Excon.get(request_url, :expects => 404)
        }.to raise_error(Excon::Errors::Error)
      end
    end
  end

  describe "VCR.configuration.after_library_hooks_loaded hook" do
    it 'disables the webmock excon adapter so it does not conflict with our typhoeus hook' do
      expect(::WebMock::HttpLibAdapters::ExconAdapter).to respond_to(:disable!)
      ::WebMock::HttpLibAdapters::ExconAdapter.should_receive(:disable!)
      $excon_after_loaded_hook.conditionally_invoke
    end
  end
end

