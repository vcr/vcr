require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Net::HTTP Response extensions" do
  context 'extending an already read response' do
    # WebMock uses this extension, too, and to prevent it from automatically being included
    # (and hence, causing issues with this spec), we remove all callbacks for the duration
    # of this spec, since the absence of any callbacks will prevent WebMock from reading the response
    # and extending the response with the response extension.
    before(:all) do
      @orig_webmock_callbacks = ::WebMock::CallbackRegistry.callbacks.dup
      ::WebMock::CallbackRegistry.reset
    end

    after(:all) do
      @orig_webmock_callbacks.each do |cb|
        ::WebMock::CallbackRegistry.add_callback(cb[:options], cb[:block])
      end
    end

    def self.it_allows_the_body_to_be_read_again
      let(:expected_regex) { /You have reached this web page by typing.*example\.com/ }

      it 'allows the body to be read using #body' do
        subject.body.to_s.should =~ expected_regex
      end

      it 'allows the body to be read using #read_body' do
        subject.read_body.to_s.should =~ expected_regex
      end

      it 'allows the body to be read using #read_body with a block' do
        yielded_body = ''
        ret_val = subject.read_body { |s| yielded_body << s }
        yielded_body.should =~ expected_regex
        ret_val.should be_instance_of(Net::ReadAdapter)
      end

      it 'allows the body to be read by passing a destination string to #read_body' do
        dest = ''
        ret_val = subject.read_body(dest)
        dest.should =~ expected_regex
        ret_val.should == dest
      end

      it 'raises an ArgumentError if both a destination string and a block is given to #read_body' do
        dest = ''
        expect { subject.read_body(dest) { |s| } }.should raise_error(ArgumentError, 'both arg and block given for HTTP method')
      end

      it 'raises an IOError when #read_body is called twice with a block' do
        subject.read_body { |s| }
        expect { subject.read_body { |s| } }.to raise_error(IOError, /read_body called twice/)
      end

      it 'raises an IOError when #read_body is called twice with a destination string' do
        dest = ''
        subject.read_body(dest)
        expect { subject.read_body(dest) }.to raise_error(IOError, /read_body called twice/)
      end
    end

    context 'when the body has already been read using #read_body and a dest string' do
      subject do
        http = Net::HTTP.new('example.com', 80)
        dest = ''
        response = http.request_get('/') { |res| res.read_body(dest) }
        response.extend VCR::Net::HTTPResponse
        response
      end

      it_allows_the_body_to_be_read_again
    end

    context 'when the body has already been read using #body' do
      subject do
        http = Net::HTTP.new('example.com', 80)
        response = http.request_get('/')
        response.body
        response.extend VCR::Net::HTTPResponse
        response
      end

      it_allows_the_body_to_be_read_again
    end
  end
end
