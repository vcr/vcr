require 'spec_helper'

describe VCR::Configuration do
  describe '#cassette_library_dir=' do
    let(:tmp_dir) { VCR::SPEC_ROOT + '/../tmp/cassette_library_dir/new_dir' }
    after(:each)  { FileUtils.rm_rf tmp_dir }

    it 'creates the directory if it does not exist' do
      expect { subject.cassette_library_dir = tmp_dir }.to change { File.exist?(tmp_dir) }.from(false).to(true)
    end

    it 'does not raise an error if given nil' do
      expect { subject.cassette_library_dir = nil }.to_not raise_error
    end

    it 'resolves the given directory to an absolute path, so VCR continues to work even if the current directory changes' do
      relative_dir = 'tmp/cassette_library_dir/new_dir'
      subject.cassette_library_dir = relative_dir
      absolute_dir = File.join(VCR::SPEC_ROOT.sub(/\/spec\z/, ''), relative_dir)
      subject.cassette_library_dir.should eq(absolute_dir)
    end
  end

  describe '#default_cassette_options' do
    it 'has a hash with some defaults' do
      subject.default_cassette_options.should eq({
        :match_requests_on => VCR::RequestMatcherRegistry::DEFAULT_MATCHERS,
        :record            => :once,
        :serialize_with    => :yaml
      })
    end

    it "returns #{VCR::RequestMatcherRegistry::DEFAULT_MATCHERS.inspect} for :match_requests_on when other defaults have been set" do
      subject.default_cassette_options = { :record => :none }
      subject.default_cassette_options.should include(:match_requests_on => VCR::RequestMatcherRegistry::DEFAULT_MATCHERS)
    end

    it "returns :once for :record when other defaults have been set" do
      subject.default_cassette_options = { :erb => :true }
      subject.default_cassette_options.should include(:record => :once)
    end

    it "allows defaults to be overriden" do
      subject.default_cassette_options = { :record => :all }
      subject.default_cassette_options.should include(:record => :all)
    end

    it "allows other keys to be set" do
      subject.default_cassette_options = { :re_record_interval => 10 }
      subject.default_cassette_options.should include(:re_record_interval => 10)
    end
  end

  describe '#register_request_matcher' do
    it 'registers the given request matcher' do
      expect {
        VCR.request_matchers[:custom]
      }.to raise_error(VCR::UnregisteredMatcherError)

      matcher_run = false
      subject.register_request_matcher(:custom) { |r1, r2| matcher_run = true }
      VCR.request_matchers[:custom].matches?(:r1, :r2)
      matcher_run.should be_true
    end
  end

  describe '#hook_into' do
    it 'requires the named library hook' do
      subject.should_receive(:require).with("vcr/library_hooks/fakeweb")
      subject.should_receive(:require).with("vcr/library_hooks/excon")
      subject.hook_into :fakeweb, :excon
    end

    it 'raises an error for unsupported stubbing libraries' do
      expect {
        subject.hook_into :unsupported_library
      }.to raise_error(ArgumentError, /unsupported_library is not a supported VCR HTTP library hook/i)
    end

    it 'invokes the after_library_hooks_loaded hooks' do
      called = false
      subject.after_library_hooks_loaded { called = true }
      subject.hook_into :fakeweb
      called.should be_true
    end
  end

  describe '#ignore_hosts' do
    it 'delegates to the current request_ignorer instance' do
      VCR.request_ignorer.should_receive(:ignore_hosts).with('example.com', 'example.net')
      subject.ignore_hosts 'example.com', 'example.net'
    end
  end

  describe '#ignore_localhost=' do
    it 'delegates to the current request_ignorer instance' do
      VCR.request_ignorer.should_receive(:ignore_localhost=).with(true)
      subject.ignore_localhost = true
    end
  end

  describe '#ignore_request' do
    it 'registers the given block with the request ignorer' do
      block_called = false
      subject.ignore_request { |r| block_called = true }
      VCR.request_ignorer.ignore?(stub(:uri => 'http://foo.com/'))
      block_called.should be_true
    end
  end

  describe '#allow_http_connections_when_no_cassette=' do
    [true, false].each do |val|
      it "sets the allow_http_connections_when_no_cassette to #{val} when set to #{val}" do
        subject.allow_http_connections_when_no_cassette = val
        subject.allow_http_connections_when_no_cassette?.should eq(val)
      end
    end
  end

  %w[ filter_sensitive_data define_cassette_placeholder ].each do |method|
    describe "##{method}" do
      let(:interaction) { mock('interaction') }
      before(:each) { interaction.stub(:filter!) }

      it 'adds a before_record hook that replaces the string returned by the block with the given string' do
        subject.send(method, 'foo', &lambda { 'bar' })
        interaction.should_receive(:filter!).with('bar', 'foo')
        subject.invoke_hook(:before_record, interaction)
      end

      it 'adds a before_playback hook that replaces the given string with the string returned by the block' do
        subject.send(method, 'foo', &lambda { 'bar' })
        interaction.should_receive(:filter!).with('foo', 'bar')
        subject.invoke_hook(:before_playback, interaction)
      end

      it 'tags the before_record hook when given a tag' do
        subject.should_receive(:before_record).with(:my_tag)
        subject.send(method, 'foo', :my_tag) { 'bar' }
      end

      it 'tags the before_playback hook when given a tag' do
        subject.should_receive(:before_playback).with(:my_tag)
        subject.send(method, 'foo', :my_tag) { 'bar' }
      end

      it 'yields the interaction to the block for the before_record hook' do
        yielded_interaction = nil
        subject.send(method, 'foo', &lambda { |i| yielded_interaction = i; 'bar' })
        subject.invoke_hook(:before_record, interaction)
        yielded_interaction.should equal(interaction)
      end

      it 'yields the interaction to the block for the before_playback hook' do
        yielded_interaction = nil
        subject.send(method, 'foo', &lambda { |i| yielded_interaction = i; 'bar' })
        subject.invoke_hook(:before_playback, interaction)
        yielded_interaction.should equal(interaction)
      end
    end
  end

  describe "#around_http_request, when called on ruby 1.8" do
    it 'raises an error since fibers are not available' do
      expect {
        subject.around_http_request { }
      }.to raise_error(/requires fibers, which are not available/)
    end
  end if RUBY_VERSION < '1.9'

  describe "#cassette_serializers" do
    let(:custom_serializer) { stub }
    it 'allows a custom serializer to be registered' do
      expect { subject.cassette_serializers[:custom] }.to raise_error(ArgumentError)
      subject.cassette_serializers[:custom] = custom_serializer
      subject.cassette_serializers[:custom].should be(custom_serializer)
    end
  end
end
