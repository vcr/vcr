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
    before(:each) do
      VCR.instance_variable_set(:@http_stubbing_adapter, nil)
    end

    {
      :fakeweb => VCR::HttpStubbingAdapters::FakeWeb,
      :webmock => VCR::HttpStubbingAdapters::WebMock
    }.each do |setting, adapter|
      context 'when config http_stubbing_adapter = :#{setting.to_s}' do
        before(:each) { VCR::Config.http_stubbing_adapter = setting }
        subject { VCR.http_stubbing_adapter }

        it "returns #{adapter}" do
          subject.should == adapter
        end

        it "disallows http connections" do
          adapter.should respond_to(:http_connections_allowed=)
          adapter.should_receive(:http_connections_allowed=).with(false)
          subject
        end

        it "checks the adapted library's version to make sure it's compatible with VCR" do
          adapter.should respond_to(:check_version!)
          adapter.should_receive(:check_version!)
          subject
        end
      end
    end

    it 'raises an error when adapter is not set' do
      VCR::Config.http_stubbing_adapter = nil
      lambda { VCR.http_stubbing_adapter }.should raise_error(/The http stubbing adapter is not configured correctly/)
    end
  end
end
