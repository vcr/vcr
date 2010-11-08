require 'spec_helper'

describe VCR do
  def insert_cassette
    VCR.insert_cassette(:cassette_test)
  end

  describe '.insert_cassette' do
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

  describe '.eject_cassette' do
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

  describe '.use_cassette' do
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

    it 'does not eject a cassette if there was an error inserting it' do
      VCR.should_receive(:insert_cassette).and_raise(StandardError.new('Boom!'))
      VCR.should_not_receive(:eject_cassette)
      lambda { VCR.use_cassette(:test) { } }.should raise_error(StandardError, 'Boom!')
    end
  end

  describe '.config' do
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

  describe '.cucumber_tags' do
    it 'yields a cucumber tags object' do
      yielded_object = nil
      VCR.cucumber_tags do |obj|
        yielded_object = obj
      end
      yielded_object.should be_instance_of(VCR::CucumberTags)
    end
  end

  describe '.http_stubbing_adapter' do
    subject { VCR.http_stubbing_adapter }
    before(:each) do
      VCR.instance_variable_set(:@http_stubbing_adapter, nil)
    end

    it 'returns a multi object proxy for the configured stubbing libraries when multiple libs are configured' do
      VCR::Config.stub_with :fakeweb, :typhoeus
      VCR.http_stubbing_adapter.proxied_objects.should == [
        VCR::HttpStubbingAdapters::FakeWeb,
        VCR::HttpStubbingAdapters::Typhoeus
      ]
    end

    {
      :fakeweb  => VCR::HttpStubbingAdapters::FakeWeb,
      :typhoeus => VCR::HttpStubbingAdapters::Typhoeus,
      :webmock  => VCR::HttpStubbingAdapters::WebMock
    }.each do |symbol, klass|
      it "returns #{klass} for :#{symbol}" do
        VCR::Config.stub_with symbol
        VCR.http_stubbing_adapter.should == klass
      end
    end

    it 'raises an error if both :fakeweb and :webmock are configured' do
      VCR::Config.stub_with :fakeweb, :webmock

      expect { VCR.http_stubbing_adapter }.to raise_error(ArgumentError, /cannot use both/)
    end

    it 'raises an error for unsupported stubbing libraries' do
      VCR::Config.stub_with :unsupported_library

      expect { VCR.http_stubbing_adapter }.to raise_error(ArgumentError, /unsupported_library is not a supported HTTP stubbing library/i)
    end

    it 'raises an error when no stubbing libraries are configured' do
      VCR::Config.stub_with

      expect { VCR.http_stubbing_adapter }.to raise_error(ArgumentError, /the http stubbing library is not configured/i)
    end
  end

  describe '.record_http_interaction' do
    before(:each) { VCR.stub!(:current_cassette).and_return(current_cassette) }

    def self.with_ignore_localhost_set_to(value, &block)
      context "when http_stubbing_adapter.ignore_localhost is #{value}" do
        before(:each) { VCR.http_stubbing_adapter.stub!(:ignore_localhost?).and_return(value) }

        instance_eval(&block)
      end
    end

    def self.it_records_requests_to(host)
      it "records requests to #{host}" do
        interaction = stub(:uri => "http://#{host}/")
        current_cassette.should_receive(:record_http_interaction).with(interaction).once
        VCR.record_http_interaction(interaction)
      end
    end

    def self.it_does_not_record_requests_to(host)
      it "does not record requests to #{host}" do
        interaction = stub(:uri => "http://#{host}/")
        current_cassette.should_receive(:record_http_interaction).never unless current_cassette.nil?
        VCR.record_http_interaction(interaction)
      end
    end

    context 'when there is a current cassette' do
      let(:current_cassette) { mock('current casette') }

      with_ignore_localhost_set_to(true) do
        it_records_requests_to "example.com"

        VCR::LOCALHOST_ALIASES.each do |host|
          it_does_not_record_requests_to host
        end
      end

      with_ignore_localhost_set_to(false) do
        (VCR::LOCALHOST_ALIASES + ['example.com']).each do |host|
          it_records_requests_to host
        end
      end
    end

    context 'when there is not a current cassette' do
      let(:current_cassette) { nil }

      with_ignore_localhost_set_to(true) do
        (VCR::LOCALHOST_ALIASES + ['example.com']).each do |host|
          it_does_not_record_requests_to host
        end
      end

      with_ignore_localhost_set_to(false) do
        (VCR::LOCALHOST_ALIASES + ['example.com']).each do |host|
          it_does_not_record_requests_to host
        end
      end
    end
  end
end
