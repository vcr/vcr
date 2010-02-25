require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "FakeWebExtensions" do
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
end