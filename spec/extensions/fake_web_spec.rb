require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "FakeWeb Extensions" do
  describe "#remove_from_registry with (:get, 'http://example.com')" do
    before(:each) do
      FakeWeb.register_uri(:get, 'http://example.com', :body => "Example dot com!")
      FakeWeb.register_uri(:post, 'http://example.com', :body => "Example dot com!")
      FakeWeb.register_uri(:get, 'http://google.com', :body => "Google dot com!")
      @remove_example_dot_com = lambda { FakeWeb.remove_from_registry(:get, 'http://example.com') }
    end

    it "removes the :get http://example.com registration" do
      @remove_example_dot_com.should change { FakeWeb.registered_uri?(:get, 'http://example.com') }.from(true).to(false)
    end

    it "does not remove the :post http://example.com registration" do
      FakeWeb.registered_uri?(:post, 'http://example.com').should be_true
      @remove_example_dot_com.should_not change { FakeWeb.registered_uri?(:post, 'http://example.com') }
    end

    it "does not affect other registered uris" do
      FakeWeb.registered_uri?(:get, 'http://google.com').should be_true
      @remove_example_dot_com.should_not change { FakeWeb.registered_uri?(:get, 'http://google.com') }
    end
  end

  describe 'FakeWeb::NetConnectNotAllowedError#message' do
    it 'includes a note about VCR' do
      FakeWeb::NetConnectNotAllowedError.new('The fakeweb error message').message.should ==
      'The fakeweb error message.  You can use VCR to automatically record this request and replay it later with fakeweb.  For more details, see the VCR README at: http://github.com/myronmarston/vcr'
    end
  end

  describe "#with_allow_net_connect_set_to" do
    it 'sets allow_net_connect for the duration of the block to the provided value' do
      [true, false].each do |expected|
        yielded_value = :not_set
        FakeWeb.with_allow_net_connect_set_to(expected) { yielded_value = FakeWeb.allow_net_connect? }
        yielded_value.should == expected
      end
    end

    it 'returns the value returned by the block' do
      FakeWeb.with_allow_net_connect_set_to(true) { :return_value }.should == :return_value
    end

    it 'reverts allow_net_connect when the block completes' do
      [true, false].each do |expected|
        FakeWeb.allow_net_connect = expected
        FakeWeb.with_allow_net_connect_set_to(true) { }
        FakeWeb.allow_net_connect?.should == expected
      end
    end

    it 'reverts allow_net_connect when the block completes, even if an error is raised' do
      [true, false].each do |expected|
        FakeWeb.allow_net_connect = expected
        lambda { FakeWeb.with_allow_net_connect_set_to(true) { raise RuntimeError } }.should raise_error(RuntimeError)
        FakeWeb.allow_net_connect?.should == expected
      end
    end
  end
end