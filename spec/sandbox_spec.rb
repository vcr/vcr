require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR::Sandbox do
  before(:each) do
    FakeWeb.clean_registry
  end

  describe '#cache_file' do
    temp_dir File.expand_path(File.dirname(__FILE__) + '/fixtures/cache_file'), :assign_to_cache_dir => true

    it 'should combine the cache_dir with the sandbox name' do
      sandbox = VCR::Sandbox.new('the_cache_file')
      sandbox.cache_file.should == File.join(VCR::Config.cache_dir, 'the_cache_file.yml')
    end

    it 'should strip out disallowed characters so that it is a valid file name with no spaces' do
      sandbox = VCR::Sandbox.new("\nthis \t! / is-the_13212_file name")
      sandbox.cache_file.should =~ /#{Regexp.escape('_this_is-the_13212_file_name.yml')}$/
    end

    it 'should return nil if the cache_dir is not set' do
      VCR::Config.cache_dir = nil
      sandbox = VCR::Sandbox.new('the_cache_file')
      sandbox.cache_file.should be_nil
    end
  end

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
    it "should raise an error if given an invalid record mode" do
      lambda { VCR::Sandbox.new(:test, :record => :not_a_record_mode) }.should raise_error(ArgumentError)
    end

    VCR::Sandbox::VALID_RECORD_MODES.each do |mode|
      it "should default the record mode to #{mode} when VCR::Config.default_sandbox_record_mode is #{mode}" do
        VCR::Config.default_sandbox_record_mode = mode
        sandbox = VCR::Sandbox.new(:test)
        sandbox.record_mode.should == mode
      end
    end

    { :unregistered => true, :all => true, :none => false }.each do |record_mode, allow_fakeweb_connect|
      it "should set FakeWeb.allow_net_connect to #{allow_fakeweb_connect} when the record mode is #{record_mode}" do
        FakeWeb.allow_net_connect = !allow_fakeweb_connect
        VCR::Sandbox.new(:name, :record => record_mode)
        FakeWeb.allow_net_connect?.should == allow_fakeweb_connect
      end
    end

    { :unregistered => true, :all => false, :none => true }.each do |record_mode, load_responses|
      it "should #{'not ' unless load_responses}load the recorded responses from the cached yml file when the record mode is #{record_mode}" do
        VCR::Config.cache_dir = File.expand_path(File.dirname(__FILE__) + '/fixtures/sandbox_spec')
        sandbox = VCR::Sandbox.new('example', :record => record_mode)

        if load_responses
          sandbox.should have(2).recorded_responses

          rr1, rr2 = sandbox.recorded_responses.first, sandbox.recorded_responses.last

          rr1.method.should == :get
          rr1.uri.should == 'http://example.com:80/'
          rr1.response.body.should =~ /You have reached this web page by typing.+example\.com/

          rr2.method.should == :get
          rr2.uri.should == 'http://example.com:80/foo'
          rr2.response.body.should =~ /foo was not found on this server/
        else
          sandbox.should have(0).recorded_responses
        end
      end

      it "should #{'not ' unless load_responses}register the recorded responses with fakeweb when the record mode is #{record_mode}" do
        VCR::Config.cache_dir = File.expand_path(File.dirname(__FILE__) + '/fixtures/sandbox_spec')
        sandbox = VCR::Sandbox.new('example', :record => record_mode)

        rr1 = FakeWeb.response_for(:get, "http://example.com")
        rr2 = FakeWeb.response_for(:get, "http://example.com/foo")

        if load_responses
          rr1.should_not be_nil
          rr2.should_not be_nil
          rr1.body.should =~ /You have reached this web page by typing.+example\.com/
          rr2.body.should =~ /foo was not found on this server/
        else
          rr1.should be_nil
          rr2.should be_nil
        end
      end
    end
  end

  describe '#destroy!' do
    temp_dir File.expand_path(File.dirname(__FILE__) + '/fixtures/sandbox_spec_destroy'), :assign_to_cache_dir => true

    [true, false].each do |orig_allow_net_connect|
      it "should reset FakeWeb.allow_net_connect #{orig_allow_net_connect} if it was originally #{orig_allow_net_connect}" do
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

      lambda { sandbox.destroy! }.should change { File.exist?(sandbox.cache_file) }.from(false).to(true)
      saved_recorded_responses = File.open(sandbox.cache_file, "r") { |f| YAML.load(f.read) }
      saved_recorded_responses.should == recorded_responses
    end

    it "should write both old and new recorded responses to disk" do
      cache_file = File.expand_path(File.dirname(__FILE__) + '/fixtures/sandbox_spec/example.yml')
      FileUtils.cp cache_file, File.join(@temp_dir, 'previously_recorded_responses.yml')
      sandbox = VCR::Sandbox.new('previously_recorded_responses')
      sandbox.should have(2).recorded_responses
      new_recorded_response = VCR::RecordedResponse.new(:get, 'http://example.com/bar', :example_dot_com_bar_response)
      sandbox.store_recorded_response!(new_recorded_response)
      sandbox.destroy!
      saved_recorded_responses = File.open(sandbox.cache_file, "r") { |f| YAML.load(f.read) }
      saved_recorded_responses.should have(3).recorded_responses
      saved_recorded_responses.last.should == new_recorded_response
    end
  end

  describe '#destroy for a sandbox with previously recorded responses' do
    it "should de-register the recorded responses from fakeweb" do
      VCR::Config.cache_dir = File.expand_path(File.dirname(__FILE__) + '/fixtures/sandbox_spec')
      sandbox = VCR::Sandbox.new('example', :record => :none)
      FakeWeb.registered_uri?(:get, 'http://example.com').should be_true
      FakeWeb.registered_uri?(:get, 'http://example.com/foo').should be_true
      sandbox.destroy!
      FakeWeb.registered_uri?(:get, 'http://example.com').should be_false
      FakeWeb.registered_uri?(:get, 'http://example.com/foo').should be_false
    end

    it "should not re-write to disk the previously recorded resposes if there are no new ones" do
      VCR::Config.cache_dir = File.expand_path(File.dirname(__FILE__) + '/fixtures/sandbox_spec')
      yaml_file = File.join(VCR::Config.cache_dir, 'example.yml')
      sandbox = VCR::Sandbox.new('example', :record => :none)
      File.should_not_receive(:open).with(sandbox.cache_file, 'w')
      lambda { sandbox.destroy! }.should_not change { File.mtime(yaml_file) }
    end
  end
end