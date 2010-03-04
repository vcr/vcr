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
end