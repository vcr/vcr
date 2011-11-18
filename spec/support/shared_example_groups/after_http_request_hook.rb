shared_examples_for "after_http_request hook" do
  let(:request_url) { "http://localhost:#{VCR::SinatraApp.port}/foo" }

  def make_request(disabled = false)
    make_http_request(:get, request_url)
  end

  def assert_expected_response(response)
    response.status.code.should eq(200)
    response.body.should eq('FOO!')
  end

  it 'invokes the hook only once per request' do
    call_count = 0
    VCR.configure do |c|
      c.after_http_request { |r| call_count += 1 }
    end
    make_request
    call_count.should eq(1)
  end

  it 'yields the request to the hook' do
    request = nil
    VCR.configure do |c|
      c.after_http_request { |r| request = r }
    end
    make_request
    request.method.should be(:get)
    request.uri.should eq(request_url)
  end

  it 'yields the response to the hook if a second block arg is given' do
    response = nil
    VCR.configure do |c|
      c.after_http_request { |req, res| response = res }
    end
    make_request
    assert_expected_response(response)
  end

  it 'does not run the hook if the library hook is disabled' do
    VCR.library_hooks.should respond_to(:disabled?)
    VCR.library_hooks.stub(:disabled? => true)

    hook_called = false
    VCR.configure do |c|
      c.after_http_request { |r| hook_called = true }
    end

    make_request(:disabled)
    hook_called.should be_false
  end
end

