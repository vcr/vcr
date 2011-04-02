require 'spec_helper'

describe VCR do
  def insert_cassette(name = :cassette_test)
    VCR.insert_cassette(name)
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

    it 'raises an error if the stack of inserted cassettes already contains a cassette with the same name' do
      insert_cassette(:foo)
      expect {
        insert_cassette(:foo)
      }.to raise_error(/There is already a cassette with the same name/)
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
      cassette1, cassette2 = insert_cassette(:foo1), insert_cassette(:foo2)
      expect { VCR.eject_cassette }.to change(VCR, :current_cassette).from(cassette2).to(cassette1)
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
      VCR.use_cassette(:cassette_test, &lambda { yielded = true })
      yielded.should be_true
    end

    it 'yields the cassette instance if the block expects an argument' do
      VCR.use_cassette('name', :record => :new_episodes, &lambda do |cassette|
        cassette.should equal(VCR.current_cassette)
      end)
    end

    it 'yields the cassette instance if the block expects a variable number of args' do
      VCR.use_cassette('name', :record => :new_episodes) do |*args|
        args.size.should == 1
        args.first.should equal(VCR.current_cassette)
      end
    end

    it 'ejects the cassette' do
      VCR.should_receive(:eject_cassette)
      VCR.use_cassette(:cassette_test) { }
    end

    it 'ejects the cassette even if there is an error' do
      VCR.should_receive(:eject_cassette)
      expect { VCR.use_cassette(:cassette_test) { raise StandardError } }.to raise_error
    end

    it 'does not eject a cassette if there was an error inserting it' do
      VCR.should_receive(:insert_cassette).and_raise(StandardError.new('Boom!'))
      VCR.should_not_receive(:eject_cassette)
      expect { VCR.use_cassette(:test) { } }.to raise_error(StandardError, 'Boom!')
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

    it "sets http_stubbing_adapter.http_connections_allowed to the configured default" do
      VCR.http_stubbing_adapter.should respond_to(:set_http_connections_allowed_to_default)
      VCR.http_stubbing_adapter.should_receive(:set_http_connections_allowed_to_default)
      VCR.config { }
    end

    it "checks the adapted library's version to make sure it's compatible with VCR" do
      VCR.http_stubbing_adapter.should respond_to(:check_version!)
      VCR.http_stubbing_adapter.should_receive(:check_version!)
      VCR.config { }
    end

    it "sets http_stubbing_adapter.ignored_hosts to the configured hosts when the block completes" do
      VCR::Config.reset!(nil)
      VCR::HttpStubbingAdapters::FakeWeb.send(:ignored_hosts).should be_empty

      VCR.config do |c|
        c.stub_with :fakeweb
        c.ignore_hosts 'example.com', 'example.org'
      end

      VCR::HttpStubbingAdapters::FakeWeb.send(:ignored_hosts).should == %w[example.com example.org]
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

    it 'returns a multi object proxy for the configured stubbing libraries when multiple libs are configured', :unless => RUBY_PLATFORM == 'java' do
      VCR::Config.stub_with :fakeweb, :typhoeus
      VCR.http_stubbing_adapter.proxied_objects.should == [
        VCR::HttpStubbingAdapters::FakeWeb,
        VCR::HttpStubbingAdapters::Typhoeus
      ]
    end

    {
      :fakeweb  => VCR::HttpStubbingAdapters::FakeWeb,
      :webmock  => VCR::HttpStubbingAdapters::WebMock,
      :faraday  => VCR::HttpStubbingAdapters::Faraday,
      :excon    => VCR::HttpStubbingAdapters::Excon
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
    before(:each) { VCR.stub(:current_cassette => current_cassette) }
    let(:uri) { 'http://some-host.com/' }
    let(:interaction) { stub(:uri => uri) }

    context 'when there is not a current cassette' do
      let(:current_cassette) { nil }

      it 'does not record a request' do
        # we can't set a message expectation on nil, but there is no place to record it to...
        # this mostly tests that there is no error.
        VCR::Config.stub(:uri_should_be_ignored? => false)
        VCR.record_http_interaction(interaction)
      end
    end

    context 'when there is a current cassette' do
      let(:current_cassette) { mock('current cassette') }

      it 'records the request when the uri should not be ignored' do
        VCR::Config.stub(:uri_should_be_ignored?).with(uri).and_return(false)
        current_cassette.should_receive(:record_http_interaction).with(interaction)
        VCR.record_http_interaction(interaction)
      end

      it 'does not record the request when the uri should be ignored' do
        VCR::Config.stub(:uri_should_be_ignored?).with(uri).and_return(true)
        current_cassette.should_not_receive(:record_http_interaction)
        VCR.record_http_interaction(interaction)
      end
    end
  end

  describe '.turn_off!' do
    before(:each) { VCR.http_stubbing_adapter.http_connections_allowed = false }

    it 'indicates it is turned off' do
      VCR.turn_off!
      VCR.should_not be_turned_on
    end

    it 'allows http requests' do
      expect {
        VCR.turn_off!
      }.to change {
        VCR.http_stubbing_adapter.http_connections_allowed?
      }.from(false).to(true)
    end

    it 'raises an error if a cassette is in use' do
      VCR.insert_cassette('foo')
      expect {
        VCR.turn_off!
      }.to raise_error(VCR::CassetteInUseError)
    end

    it 'causes an error to be raised if you insert a cassette while VCR is turned off' do
      VCR.turn_off!
      expect {
        VCR.insert_cassette('foo')
      }.to raise_error(VCR::TurnedOffError)
    end
  end

  describe '.turn_on!' do
    before(:each) { VCR.turn_off! }

    it 'indicates it is turned on' do
      VCR.turn_on!
      VCR.should be_turned_on
    end

    it 'sets http_connections_allowed to the default' do
      VCR.http_stubbing_adapter.should respond_to(:set_http_connections_allowed_to_default)
      VCR.http_stubbing_adapter.should_receive(:set_http_connections_allowed_to_default)
      VCR.turn_on!
    end
  end

  describe '.turned_off' do
    it 'yields with VCR turned off' do
      VCR.should be_turned_on
      yielded = false

      VCR.turned_off do
        yielded = true
        VCR.should_not be_turned_on
      end

      yielded.should == true
      VCR.should be_turned_on
    end
  end

  describe '.turned_on?' do
    it 'is on by default' do
      # clear internal state
      VCR.instance_eval do
        instance_variables.each do |var|
          remove_instance_variable(var)
        end
      end

      VCR.should be_turned_on
    end
  end
end
