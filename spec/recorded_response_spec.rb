require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR::RecordedResponse do
  describe '#==' do
    before(:each) do
      @r1 = VCR::RecordedResponse.new(:get, 'http://example.com', :the_example_dot_come_response)
    end

    it 'should return true for 2 responses with the same method, uri and response' do
      @r1.should == VCR::RecordedResponse.new(@r1.method, @r1.uri, @r1.response)
    end

    it 'should return false for 2 responses with different methods' do
      @r1.should_not == VCR::RecordedResponse.new(:post, @r1.uri, @r1.response)
    end

    it 'should return false for 2 responses with different uris' do
      @r1.should_not == VCR::RecordedResponse.new(@r1.method, 'http://example.com/path', @r1.response)
    end

    it 'should return false for 2 responses with different responses' do
      @r1.should_not == VCR::RecordedResponse.new(@r1.method, @r1.uri, :another_response)
    end
  end
end