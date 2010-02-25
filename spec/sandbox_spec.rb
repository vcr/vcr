require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR::Sandbox do
  describe '#store_recorded_response!' do
    it 'should add the recorded response to #recorded_responses' do
      recorded_response = VCR::RecordedResponse.new(:get, 'http://example.com', :response)
      sandbox = VCR::Sandbox.new(:test_sandbox)
      sandbox.recorded_responses.should == []
      sandbox.store_recorded_response!(recorded_response)
      sandbox.recorded_responses.should == [recorded_response]
    end
  end

  describe 'on creation' do
    { :unregistered => true, :all => true, :none => false }.each do |record_mode, allow_fakeweb_connect|
      it "should set FakeWeb.allow_net_connect to #{allow_fakeweb_connect} when the record mode is #{record_mode}" do
        FakeWeb.allow_net_connect = !allow_fakeweb_connect
        VCR::Sandbox.new(:name, :record => record_mode)
        FakeWeb.allow_net_connect?.should == allow_fakeweb_connect
      end
    end

    it 'should load the recorded responses from the cached yml file' do
      VCR::Config.cache_dir = File.expand_path(File.dirname(__FILE__) + '/fixtures/sandbox_spec')
      sandbox = VCR::Sandbox.new('example')
      sandbox.should have(2).recorded_responses

      rr1, rr2 = sandbox.recorded_responses.first, sandbox.recorded_responses.last

      rr1.method.should == :get
      rr1.uri.should == 'http://example.com:80/'
      rr1.response.body.should =~ /You have reached this web page by typing.+example\.com/

      rr2.method.should == :get
      rr2.uri.should == 'http://example.com:80/foo'
      rr2.response.body.should =~ /foo was not found on this server/
    end
  end

  describe '#destroy!' do
    temp_dir File.expand_path(File.dirname(__FILE__) + '/fixtures/sandbox_spec_destroy'), :assign_to_cache_dir => true

    [true, false].each do |orig_allow_net_connect|
      it "should reset FakeWeb.allow_net_connect to #{orig_allow_net_connect} if it was originally #{orig_allow_net_connect}" do
        FakeWeb.allow_net_connect = orig_allow_net_connect
        sandbox = VCR::Sandbox.new(:name)
        sandbox.destroy!
        FakeWeb.allow_net_connect?.should == orig_allow_net_connect
      end
    end

    it "should write the recorded responses to disk as yaml" do
      recorded_responses = [
        VCR::RecordedResponse.new(:get,  'http://example.com', :get_example_dot_come_response),
        VCR::RecordedResponse.new(:post, 'http://example.com', :post_example_dot_come_response),
        VCR::RecordedResponse.new(:get,  'http://google.com',  :get_google_dot_come_response)
      ]

      sandbox = VCR::Sandbox.new(:destroy_test)
      sandbox.stub!(:recorded_responses).and_return(recorded_responses)

      yaml_file = File.join(@temp_dir, 'destroy_test.yml')
      lambda { sandbox.destroy! }.should change { File.exist?(yaml_file) }.from(false).to(true)
      saved_recorded_responses = File.open(yaml_file, "r") { |f| YAML.load(f.read) }
      saved_recorded_responses.should == recorded_responses
    end
  end
end