require 'vcr/structs'
require 'vcr/request_ignorer'

module VCR
  describe RequestIgnorer do
    def request(uri)
      VCR::Request.new.tap { |r| r.uri = uri }
    end

    shared_examples_for "#ignore?" do |url, expected_value|
      it "returns #{expected_value} if given a request with a url like #{url}" do
        expect(subject.ignore?(request(url))).to eq(expected_value)
      end
    end

    context 'when example.com and example.net are ignored' do
      before(:each) { subject.ignore_hosts 'example.com', 'example.net' }

      it_behaves_like "#ignore?", "http://www.example.com/foo", false
      it_behaves_like "#ignore?", "http://example.com/foo", true
      it_behaves_like "#ignore?", "http://example.net:890/foo", true
      it_behaves_like "#ignore?", "http://some-other-domain.com/", false
    end

    context 'when ignore_localhost is set to true' do
      before(:each) { subject.ignore_localhost = true }

      it_behaves_like "#ignore?", "http://some-host.com/foo", false
      RequestIgnorer::LOCALHOST_ALIASES.each do |host|
        it_behaves_like "#ignore?", "http://#{host}/foo", true
      end
    end

    context 'when ignore_localhost is not set' do
      it_behaves_like "#ignore?", "http://some-host.com/foo", false
      RequestIgnorer::LOCALHOST_ALIASES.each do |host|
        it_behaves_like "#ignore?", "http://#{host}/foo", false
      end
    end

    context 'when ignore_localhost is set to false after being set to true' do
      before(:each) do
        subject.ignore_localhost = true
        subject.ignore_localhost = false
      end

      it_behaves_like "#ignore?", "http://some-host.com/foo", false
      RequestIgnorer::LOCALHOST_ALIASES.each do |host|
        it_behaves_like "#ignore?", "http://#{host}/foo", false
      end
    end

    context 'when a custom ignore_request hook has been set' do
      before(:each) do
        subject.ignore_request do |request|
          URI(request.uri).port == 5
        end
      end

      it 'ignores requests for which the block returns true' do
        expect(subject.ignore?(request('http://foo.com:5/bar'))).to be true
      end

      it 'does not ignore requests for which the block returns false' do
        expect(subject.ignore?(request('http://foo.com:6/bar'))).to be false
      end
    end
  end
end

