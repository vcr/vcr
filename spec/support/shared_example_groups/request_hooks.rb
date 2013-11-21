shared_examples_for "request hooks" do |library_hook_name, request_type|
  let(:request_url) { "http://localhost:#{VCR::SinatraApp.port}/foo" }

  def make_request(disabled = false)
    make_http_request(:get, request_url)
  end

  def assert_expected_response(response)
    expect(response.status.code).to eq(200)
    expect(response.body).to eq('FOO!')
  end

  [:before_http_request, :after_http_request].each do |hook|
    specify "the #{hook} hook is only called once per request" do
      call_count = 0
      VCR.configuration.send(hook) { |r| call_count += 1 }

      make_request
      expect(call_count).to eq(1)
    end

    specify "the #{hook} hook yields the request" do
      request = nil
      VCR.configuration.send(hook) { |r| request = r }

      make_request
      expect(request.method).to be(:get)
      expect(request.uri).to eq(request_url)
    end

    specify "the #{hook} hook is not called if the library hook is disabled" do
      expect(VCR.library_hooks).to respond_to(:disabled?)
      allow(VCR.library_hooks).to receive(:disabled?).and_return(true)

      hook_called = false
      VCR.configuration.send(hook) { |r| hook_called = true }

      make_request(:disabled)
      expect(hook_called).to be false
    end

    specify "the #type of the yielded request given to the #{hook} hook is #{request_type}" do
      request = nil
      VCR.configuration.send(hook) { |r| request = r }

      make_request
      expect(request.type).to be(request_type)
    end
  end

  specify "the after_http_request hook yields the response if there is one and the second block arg is given" do
    response = nil
    VCR.configuration.after_http_request { |req, res| response = res }

    make_request
    assert_expected_response(response)
  end
end

