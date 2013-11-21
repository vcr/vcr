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
      expect(subject.cassette_library_dir).to eq(absolute_dir)
    end
  end

  describe '#default_cassette_options' do
    it 'has a hash with some defaults' do
      expect(subject.default_cassette_options).to eq({
        :match_requests_on => VCR::RequestMatcherRegistry::DEFAULT_MATCHERS,
        :allow_unused_http_interactions => true,
        :record            => :once,
        :serialize_with    => :yaml,
        :persist_with      => :file_system
      })
    end

    it "returns #{VCR::RequestMatcherRegistry::DEFAULT_MATCHERS.inspect} for :match_requests_on when other defaults have been set" do
      subject.default_cassette_options = { :record => :none }
      expect(subject.default_cassette_options).to include(:match_requests_on => VCR::RequestMatcherRegistry::DEFAULT_MATCHERS)
    end

    it "returns :once for :record when other defaults have been set" do
      subject.default_cassette_options = { :erb => :true }
      expect(subject.default_cassette_options).to include(:record => :once)
    end

    it "allows defaults to be overriden" do
      subject.default_cassette_options = { :record => :all }
      expect(subject.default_cassette_options).to include(:record => :all)
    end

    it "allows other keys to be set" do
      subject.default_cassette_options = { :re_record_interval => 10 }
      expect(subject.default_cassette_options).to include(:re_record_interval => 10)
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
      expect(matcher_run).to be true
    end
  end

  describe '#hook_into' do
    it 'requires the named library hook' do
      expect(subject).to receive(:require).with("vcr/library_hooks/fakeweb")
      expect(subject).to receive(:require).with("vcr/library_hooks/excon")
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
      expect(called).to be true
    end
  end

  describe '#ignore_hosts' do
    it 'delegates to the current request_ignorer instance' do
      expect(VCR.request_ignorer).to receive(:ignore_hosts).with('example.com', 'example.net')
      subject.ignore_hosts 'example.com', 'example.net'
    end
  end

  describe '#ignore_localhost=' do
    it 'delegates to the current request_ignorer instance' do
      expect(VCR.request_ignorer).to receive(:ignore_localhost=).with(true)
      subject.ignore_localhost = true
    end
  end

  describe '#ignore_request' do
    let(:uri){ URI('http://foo.com') }

    it 'registers the given block with the request ignorer' do
      block_called = false
      subject.ignore_request { |r| block_called = true }
      VCR.request_ignorer.ignore?(double(:parsed_uri => uri))
      expect(block_called).to be true
    end
  end

  describe '#allow_http_connections_when_no_cassette=' do
    [true, false].each do |val|
      it "sets the allow_http_connections_when_no_cassette to #{val} when set to #{val}" do
        subject.allow_http_connections_when_no_cassette = val
        expect(subject.allow_http_connections_when_no_cassette?).to eq(val)
      end
    end
  end

  describe "request/configuration interactions", :with_monkey_patches => :fakeweb do
    specify 'the request on the yielded interaction is not typed even though the request given to before_http_request is' do
      before_record_req = before_request_req = nil
      VCR.configure do |c|
        c.before_http_request { |r| before_request_req = r }
        c.before_record { |i| before_record_req = i.request }
      end

      VCR.use_cassette("example") do
        ::Net::HTTP.get_response(URI("http://localhost:#{VCR::SinatraApp.port}/foo"))
      end

      expect(before_record_req).not_to respond_to(:type)
      expect(before_request_req).to respond_to(:type)
    end unless (RUBY_VERSION =~ /^1\.8/ || RUBY_INTERPRETER == :jruby)

    specify 'the filter_sensitive_data option works even when it modifies the URL in a way that makes it an invalid URI' do
      VCR.configure do |c|
        c.filter_sensitive_data('<HOST>') { 'localhost' }
      end

      2.times do
        VCR.use_cassette("example") do
          ::Net::HTTP.get_response(URI("http://localhost:#{VCR::SinatraApp.port}/foo"))
        end
      end
    end
  end

  [:before_record, :before_playback].each do |hook_type|
    describe "##{hook_type}" do
      it 'sets up a tag filter' do
        called = false
        VCR.configuration.send(hook_type, :my_tag) { called = true }
        VCR.configuration.invoke_hook(hook_type, double, double(:tags => []))
        expect(called).to be false
        VCR.configuration.invoke_hook(hook_type, double, double(:tags => [:my_tag]))
        expect(called).to be true
      end
    end
  end

  %w[ filter_sensitive_data define_cassette_placeholder ].each do |method|
    describe "##{method}" do
      let(:interaction) { double('interaction').as_null_object }
      before(:each) { allow(interaction).to receive(:filter!) }

      it 'adds a before_record hook that replaces the string returned by the block with the given string' do
        subject.send(method, 'foo', &lambda { 'bar' })
        expect(interaction).to receive(:filter!).with('bar', 'foo')
        subject.invoke_hook(:before_record, interaction, double.as_null_object)
      end

      it 'adds a before_playback hook that replaces the given string with the string returned by the block' do
        subject.send(method, 'foo', &lambda { 'bar' })
        expect(interaction).to receive(:filter!).with('foo', 'bar')
        subject.invoke_hook(:before_playback, interaction, double.as_null_object)
      end

      it 'tags the before_record hook when given a tag' do
        expect(subject).to receive(:before_record).with(:my_tag)
        subject.send(method, 'foo', :my_tag) { 'bar' }
      end

      it 'tags the before_playback hook when given a tag' do
        expect(subject).to receive(:before_playback).with(:my_tag)
        subject.send(method, 'foo', :my_tag) { 'bar' }
      end

      it 'yields the interaction to the block for the before_record hook' do
        yielded_interaction = nil
        subject.send(method, 'foo', &lambda { |i| yielded_interaction = i; 'bar' })
        subject.invoke_hook(:before_record, interaction, double.as_null_object)
        expect(yielded_interaction).to equal(interaction)
      end

      it 'yields the interaction to the block for the before_playback hook' do
        yielded_interaction = nil
        subject.send(method, 'foo', &lambda { |i| yielded_interaction = i; 'bar' })
        subject.invoke_hook(:before_playback, interaction, double.as_null_object)
        expect(yielded_interaction).to equal(interaction)
      end
    end
  end

  describe "#after_http_request" do
    let(:raw_request) { VCR::Request.new }
    let(:response)    { VCR::Response.new }

    def request(type)
      VCR::Request::Typed.new(raw_request, type)
    end

    it 'handles symbol request predicate filters properly' do
      yielded = false
      subject.after_http_request(:stubbed_by_vcr?) { |req| yielded = true }
      subject.invoke_hook(:after_http_request, request(:stubbed_by_vcr), response)
      expect(yielded).to be true

      yielded = false
      subject.invoke_hook(:after_http_request, request(:ignored), response)
      expect(yielded).to be false
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
    let(:custom_serializer) { double }
    it 'allows a custom serializer to be registered' do
      expect { subject.cassette_serializers[:custom] }.to raise_error(ArgumentError)
      subject.cassette_serializers[:custom] = custom_serializer
      expect(subject.cassette_serializers[:custom]).to be(custom_serializer)
    end
  end

  describe "#cassette_persisters" do
    let(:custom_persister) { double }
    it 'allows a custom persister to be registered' do
      expect { subject.cassette_persisters[:custom] }.to raise_error(ArgumentError)
      subject.cassette_persisters[:custom] = custom_persister
      expect(subject.cassette_persisters[:custom]).to be(custom_persister)
    end
  end

  describe "#uri_parser=" do
    let(:custom_parser) { double }
    it 'allows a custom uri parser to be set' do
      subject.uri_parser = custom_parser
      expect(subject.uri_parser).to eq(custom_parser)
    end

    it "uses Ruby's standard library `URI` as a default" do
      expect(subject.uri_parser).to eq(URI)
    end
  end

  describe "#preserve_exact_body_bytes_for?" do
    def message_for(body)
      double(:body => body)
    end

    context "default hook" do
      it "returns false when there is no current cassette" do
        expect(subject.preserve_exact_body_bytes_for?(message_for "string")).to be false
      end

      it "returns false when the current cassette has been created without the :preserve_exact_body_bytes option" do
        VCR.insert_cassette('foo')
        expect(subject.preserve_exact_body_bytes_for?(message_for "string")).to be false
      end

      it 'returns true when the current cassette has been created with the :preserve_exact_body_bytes option' do
        VCR.insert_cassette('foo', :preserve_exact_body_bytes => true)
        expect(subject.preserve_exact_body_bytes_for?(message_for "string")).to be true
      end
    end

    it "returns true when the configured block returns true" do
      subject.preserve_exact_body_bytes { |msg| msg.body == "a" }
      expect(subject.preserve_exact_body_bytes_for?(message_for "a")).to be true
      expect(subject.preserve_exact_body_bytes_for?(message_for "b")).to be false
    end

    it "returns true when any of the registered blocks returns true" do
      called_hooks = []
      subject.preserve_exact_body_bytes { called_hooks << :hook_1; false }
      subject.preserve_exact_body_bytes { called_hooks << :hook_2; true }
      expect(subject.preserve_exact_body_bytes_for?(message_for "a")).to be true
      expect(called_hooks).to eq([:hook_1, :hook_2])
    end

    it "invokes the configured hook with the http message and the current cassette" do
      VCR.use_cassette('example') do |cassette|
        expect(cassette).to be_a(VCR::Cassette)
        message = double(:message)

        yielded_objects = nil
        subject.preserve_exact_body_bytes { |a, b| yielded_objects = [a, b] }
        subject.preserve_exact_body_bytes_for?(message)
        expect(yielded_objects).to eq([message, cassette])
      end
    end
  end

  describe "#configure_rspec_metadata!" do
    it "only configures the underlying metadata once, no matter how many times it is called" do
      expect(VCR::RSpec::Metadata).to receive(:configure!).once
      VCR.configure do |c|
        c.configure_rspec_metadata!
      end
      VCR.configure do |c|
        c.configure_rspec_metadata!
      end
    end
  end
end
