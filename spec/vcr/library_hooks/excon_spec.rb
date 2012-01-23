require 'spec_helper'

describe "Excon hook" do
  # TODO: figure out a way to get disabling VCR to work with Excon
  #       and allow dirct excon stubs to work.
  # def directly_stub_request(method, url, response_body)
  #   ::Excon.stub({ :method => method, :url => url }, { :body => response_body })
  # end

  it_behaves_like 'a hook into an HTTP library', :excon, 'excon', :status_message_not_exposed

  it_performs('version checking', 'Excon',
    :valid    => %w[ 0.9.5 0.9.10 ],
    :too_low  => %w[ 0.8.99 0.9.4 ],
    :too_high => %w[ 0.10.0 1.0.0 ]
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
    before(:each) do
      VCR.stub(:real_http_connections_allowed? => true)
    end

    it 'still records properly' do
      VCR.should_receive(:record_http_interaction) do |interaction|
        interaction.response.status.code.should eq(404)
      end

      expect {
        Excon.get("http://localhost:#{VCR::SinatraApp.port}/not_found", :expects => 200)
      }.to raise_error(Excon::Errors::Error)
    end

    it 'performs the right number of retries' do
      connection = Excon.new("http://localhost:#{VCR::SinatraApp.port}/not_found")

      # Excon define's .stub so we can't use RSpec's here...
      Excon.should_receive(:new).at_least(:once).and_return(connection)

      connection.extend Module.new {
        def request_kernel_call_counts
          @request_kernel_call_counts ||= Hash.new(0)
        end

        def request_kernel(params, &block)
          request_kernel_call_counts[params[:mock]] += 1
          super
        end
      }

      expect {
        connection.get(:expects => 200, :idempotent => true, :retry_limit => 3)
      }.to raise_error(Excon::Errors::Error)

      connection.request_kernel_call_counts.should eq(true => 3, false => 3)
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

      stubbed_error.class.should be(real_error.class)
    end

    it_behaves_like "request hooks", :excon do
      undef make_request
      def make_request(disabled = false)
        expect {
          Excon.get(request_url, :expects => 404)
        }.to raise_error(Excon::Errors::Error)
      end
    end
  end
end

