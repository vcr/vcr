require 'spec_helper'

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

      recorded.should eq(played_back)
      recorded.should eq('query: Tolkien')
    end
  end

  context 'when the request overrides the connection params' do
    let!(:excon) { ::Excon.new("http://localhost:#{VCR::SinatraApp.port}/") }

    def deep_dup(hash)
      Marshal.load(Marshal.dump hash)
    end

    def intercept_request(&interception)
      orig_new = ::Excon::Connection.method(:new)

      ::Excon::Connection.stub(:new) do |*args1|
        orig_new.call(*args1).tap do |inst|

          meth = inst.method(:request)
          inst.stub(:request) do |*args2|
            interception.call(inst, *args2)
            meth.call(*args2)
          end
        end
      end
    end

    it 'runs the real request with the same connection params' do
      connection_params_1 = deep_dup(excon.connection)
      connection_params_2 = nil

      intercept_request do |instance, *args|
        connection_params_2 = deep_dup(instance.connection)
      end

      VCR.use_cassette("excon") do
        excon.request(:method => :get, :path => '/foo')
      end

      connection_params_2.should eq(connection_params_1)
    end
  end

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

      Excon::Connection.stub(:new => connection)

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
      ::WebMock::HttpLibAdapters::ExconAdapter.should respond_to(:disable!)
      ::WebMock::HttpLibAdapters::ExconAdapter.should_receive(:disable!)
      $excon_after_loaded_hook.conditionally_invoke
    end
  end
end

