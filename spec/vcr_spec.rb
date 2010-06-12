require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR do
  def insert_cassette
    VCR.insert_cassette(:cassette_test)
  end

  describe 'insert_cassette' do
    it 'creates a new cassette' do
      insert_cassette.should be_instance_of(VCR::Cassette)
    end

    it 'takes over as the #current_cassette' do
      orig_cassette = VCR.current_cassette
      new_cassette = insert_cassette
      new_cassette.should_not == orig_cassette
      VCR.current_cassette.should == new_cassette
    end
  end

  describe 'eject_cassette' do
    it 'ejects the current cassette' do
      cassette = insert_cassette
      cassette.should_receive(:eject)
      VCR.eject_cassette
    end

    it 'returns the ejected cassette' do
      cassette = insert_cassette
      VCR.eject_cassette.should == cassette
    end

    it 'returns the #current_cassette to the previous one' do
      cassette1, cassette2 = insert_cassette, insert_cassette
      lambda { VCR.eject_cassette }.should change(VCR, :current_cassette).from(cassette2).to(cassette1)
    end
  end

  describe 'use_cassette' do
    it 'inserts a new cassette' do
      new_cassette = VCR::Cassette.new(:use_cassette_test)
      VCR.should_receive(:insert_cassette).and_return(new_cassette)
      VCR.use_cassette(:cassette_test) { }
    end

    it 'yields' do
      yielded = false
      VCR.use_cassette(:cassette_test) { yielded = true }
      yielded.should be_true
    end

    it 'ejects the cassette' do
      VCR.should_receive(:eject_cassette)
      VCR.use_cassette(:cassette_test) { }
    end

    it 'ejects the cassette even if there is an error' do
      VCR.should_receive(:eject_cassette)
      lambda { VCR.use_cassette(:cassette_test) { raise StandardError } }.should raise_error
    end
  end

  describe 'config' do
    it 'yields the configuration object' do
      yielded_object = nil
      VCR.config do |obj|
        yielded_object = obj
      end
      yielded_object.should == VCR::Config
    end

    it "disallows http connections" do
      VCR.http_stubbing_adapter.should respond_to(:http_connections_allowed=)
      VCR.http_stubbing_adapter.should_receive(:http_connections_allowed=).with(false)
      VCR.config { }
    end

    it "checks the adapted library's version to make sure it's compatible with VCR" do
      VCR.http_stubbing_adapter.should respond_to(:check_version!)
      VCR.http_stubbing_adapter.should_receive(:check_version!)
      VCR.config { }
    end

    [true, false].each do |val|
      it "sets http_stubbing_adapter.ignore_localhost to #{val} when so configured" do
        VCR.config do |c|
          c.ignore_localhost = val

          # this is mocked at this point since it should be set when the block completes.
          VCR.http_stubbing_adapter.should_receive(:ignore_localhost=).with(val)
        end
      end
    end
  end

  describe 'cucumber_tags' do
    it 'yields a cucumber tags object' do
      yielded_object = nil
      VCR.cucumber_tags do |obj|
        yielded_object = obj
      end
      yielded_object.should be_instance_of(VCR::CucumberTags)
    end
  end

  describe '#http_stubbing_adapter' do
    subject { VCR.http_stubbing_adapter }
    before(:each) do
      VCR.instance_variable_set(:@http_stubbing_adapter, nil)
    end

    {
      :fakeweb => VCR::HttpStubbingAdapters::FakeWeb,
      :webmock => VCR::HttpStubbingAdapters::WebMock
    }.each do |setting, adapter|
      context "when config http_stubbing_library = :#{setting.to_s}" do
        before(:each) { VCR::Config.http_stubbing_library = setting }

        it "returns #{adapter}" do
          subject.should == adapter
        end
      end
    end

    it 'raises an error when library is not set' do
      VCR::Config.http_stubbing_library = nil
      lambda { subject }.should raise_error(/The http stubbing library is not configured correctly/)
    end
  end
end
