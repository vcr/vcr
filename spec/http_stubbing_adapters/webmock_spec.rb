require 'spec_helper'

describe VCR::HttpStubbingAdapters::WebMock do
  it_should_behave_like 'an http stubbing adapter'
  it_should_behave_like 'an http stubbing adapter that supports Net::HTTP'

  context "using patron" do
    def get_body_string(response); response.body; end

    def make_http_request(method, url, body = {})
      uri = URI.parse(url)
      sess = Patron::Session.new
      sess.base_url = "#{uri.scheme}://#{uri.host}:#{uri.port}"

      case method
        when :get
          sess.get(uri.path)
        when :post
          sess.post(uri.path, body)
      end
    end

    it_should_behave_like 'an http stubbing adapter that supports some HTTP library'
  end

  context "using httpclient" do
    def get_body_string(response)
      response.body.content
    end

    def make_http_request(method, url, body = {})
      case method
        when :get
          HTTPClient.new.get(url)
        when :post
          HTTPClient.new.post(url, body)
      end
    end

    it_should_behave_like 'an http stubbing adapter that supports some HTTP library'
  end

  context "using em-http-request" do
    def get_body_string(response)
      response.response
    end

    def make_http_request(method, url, body = {})
      EventMachine.run do
        http = case method
          when :get  then EventMachine::HttpRequest.new(url).get
          when :post then EventMachine::HttpRequest.new(url).post :body => body
        end

        http.callback { EventMachine.stop; return http }
      end
    end

    it_should_behave_like 'an http stubbing adapter that supports some HTTP library'
  end

  describe '#check_version!' do
    before(:each) { WebMock.should respond_to(:version) }

    %w( 1.3.0 1.3.1 1.4.0 2.0.0 ).each do |version|
      it "does nothing when WebMock's version is #{version}" do
        WebMock.stub!(:version).and_return(version)
        expect { described_class.check_version! }.to_not raise_error
      end
    end

    %w( 0.9.9 0.9.10 0.1.30 1.0.30 1.2.9 ).each do |version|
      it "raises an error when WebMock's version is #{version}" do
        WebMock.stub!(:version).and_return(version)
        expect { described_class.check_version! }.to raise_error(/You are using WebMock #{version}.  VCR requires version .* or greater/)
      end
    end
  end
end
