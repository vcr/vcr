require 'spec_helper'

RSpec.describe "Typhoeus hook", :with_monkey_patches => :typhoeus, :if => (RUBY_INTERPRETER == :mri) do
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
      recorded = get_response
      played_back = get_response

      expect(played_back.headers).to eq(recorded.headers)
    end
  end

  context 'when a request is made with a hash for the POST body' do
    let(:body) { { foo: "17" }.to_json }

    def make_request
      VCR.use_cassette("hash_body") do
        Typhoeus::Request.post(
          "http://localhost:#{VCR::SinatraApp.port}/return-request-body",
          headers: {'Content-Type'=> "application/json"},
          body: body
        )
      end
    end

    it 'records and replays correctly' do
      recorded = make_request
      played_back = make_request

      expect(recorded.body).to eq(body)
      expect(played_back.body).to eq(recorded.body)
    end
  end

  context 'when using on_headers callback' do
    def on_headers(&callback)
      callback = Proc.new {} unless block_given?

      VCR.use_cassette('on_headers') { request.tap { |r| r.on_headers(&callback) }.run }
    end

    let(:request) { Typhoeus::Request.new("http://localhost:#{VCR::SinatraApp.port}/localhost_test") }

    it { expect(request.tap { |r| r.on_headers {} }).not_to be_streaming }

    it { expect { |b| on_headers(&b) }.to yield_with_args(have_attributes(headers: hash_including('Content-Length' => '18'))) }
    it { expect { |b| on_headers(&b) }.to yield_with_args(have_attributes(headers: match_array(on_headers.headers))) }

    it { expect(on_headers).to have_attributes(headers: hash_including("Content-Length" => "18")) }
    it { expect(on_headers).to have_attributes(headers: match_array(on_headers.headers))  }
  end

  context 'when using on_body callback' do
    def on_body(&callback)
      callback = Proc.new {} unless block_given?

      VCR.use_cassette('no_body') { request.tap { |r| r.on_body(&callback) }.run }
    end

    def request
      Typhoeus::Request.new("http://localhost:#{VCR::SinatraApp.port}/localhost_test")
    end

    it { expect(request.tap { |r| r.on_body {} }).to be_streaming }

    it { expect(on_body).to have_attributes(body: 'Localhost response') }
    it { expect(on_body).to have_attributes(body: on_body.body)  }

    it { expect { |b| on_body(&b) }.to yield_with_args('Localhost response', have_attributes(body: '')) }
    it { expect { |b| on_body(&b) }.to yield_with_args(on_body.body, have_attributes(body: 'Localhost response')) }

    it { expect(on_body { next :abort }).to have_attributes(body: on_body.body)  }
    it { expect(on_body { next :abort }).to have_attributes(body: on_body { next :abort }.body)  }
    it { expect(on_body).to have_attributes(body: on_body { next :abort }.body)  }
  end

  context '#effective_url' do
    ResponseValues = Struct.new(:status, :body, :effective_url)

    def url_for(path)
      "http://localhost:#{VCR::SinatraApp.port}#{path}"
    end

    def make_single_request(path, options = {})
      VCR.use_cassette('single') do |cassette|
        response = Typhoeus::Request.new(url_for(path), options).run

        yield cassette if block_given?

        ResponseValues.new(
          response.code,
          response.body,
          response.effective_url
        )
      end
    end

    it 'records and plays back properly' do
      recorded = make_single_request('/')
      played_back = make_single_request('/')

      expect(recorded.effective_url).to eq(url_for('/'))
      expect(played_back).to eq(recorded)
    end

    it 'falls back to the request url when it was not recorded (e.g. on VCR <= 2.5.0)' do
      make_single_request('/') do |cassette|
        cassette.new_recorded_interactions.each { |i| i.response.adapter_metadata.clear }
      end

      played_back = make_single_request('/')
      expect(played_back.effective_url).to eq(url_for('/'))
    end

    context "when following redirects" do
      it 'records and plays back properly' do
        recorded = make_single_request('/redirect-to-root', :followlocation => true)
        played_back = make_single_request('/redirect-to-root', :followlocation => true)

        expect(recorded.effective_url).to eq(url_for('/'))
        expect(played_back).to eq(recorded)
      end
    end
  end
end

