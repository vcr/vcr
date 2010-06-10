require 'spec_helper'

describe VCR::HttpStubbingAdapters::WebMock do
  it_should_behave_like 'an http stubbing adapter'
  it_should_behave_like 'an http stubbing adapter that supports Net::HTTP'

  context "using patron" do
    let(:patron_session) do
      sess = Patron::Session.new
      sess.base_url = 'http://example.com'
      sess
    end

    def get_body_string(response); response.body; end

    def make_http_request(method, path, body = {})
      case method
        when :get
          patron_session.get(path)
        when :post
          patron_session.post(path, body)
      end
    end

    it_should_behave_like 'an http stubbing adapter that supports some HTTP library'
  end

  context "using httpclient" do
    def get_body_string(response)
      response.body.content
    end

    def make_http_request(method, path, body = {})
      case method
        when :get
          HTTPClient.new.get("http://example.com#{path}")
        when :post
          HTTPClient.new.post("http://example.com#{path}", body)
      end
    end

    it_should_behave_like 'an http stubbing adapter that supports some HTTP library'
  end

  describe '#check_version!' do
    before(:each) { WebMock.should respond_to(:version) }

    %w( 1.1.0 1.1.1 1.2.0 2.0.0 ).each do |version|
      it "does nothing when WebMock's version is #{version}" do
        WebMock.stub!(:version).and_return(version)
        expect { described_class.check_version! }.to_not raise_error
      end
    end

    %w( 0.9.9 0.9.10 0.1.30 1.0.30 ).each do |version|
      it "raises an error when WebMock's version is #{version}" do
        WebMock.stub!(:version).and_return(version)
        expect { described_class.check_version! }.to raise_error(/You are using WebMock #{version}.  VCR requires version .* or greater/)
      end
    end
  end
end
