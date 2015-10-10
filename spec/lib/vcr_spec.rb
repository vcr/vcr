require 'spec_helper'

describe VCR do
  def insert_cassette(name = :cassette_test)
    VCR.insert_cassette(name)
  end

  describe '.insert_cassette' do
    it 'creates a new cassette' do
      expect(insert_cassette).to be_instance_of(VCR::Cassette)
    end

    it 'takes over as the #current_cassette' do
      orig_cassette = VCR.current_cassette
      new_cassette = insert_cassette
      expect(new_cassette).not_to eq(orig_cassette)
      expect(VCR.current_cassette).to eq(new_cassette)
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
      expect(cassette).to receive(:eject)
      VCR.eject_cassette
    end

    it 'forwards the given options to `Cassette#eject`' do
      cassette = insert_cassette
      expect(cassette).to receive(:eject).with(:some => :options)
      VCR.eject_cassette(:some => :options)
    end

    it 'returns the ejected cassette' do
      cassette = insert_cassette
      expect(VCR.eject_cassette).to eq(cassette)
    end

    it 'returns the #current_cassette to the previous one' do
      cassette1, cassette2 = insert_cassette(:foo1), insert_cassette(:foo2)
      expect { VCR.eject_cassette }.to change(VCR, :current_cassette).from(cassette2).to(cassette1)
    end

    it 'keeps the cassette as the current one until after #eject has finished' do
      cassette = insert_cassette
      current = nil
      allow(cassette).to receive(:eject) { current = VCR.current_cassette }

      VCR.eject_cassette

      expect(current).to be(cassette)
      expect(VCR.current_cassette).not_to be(cassette)
    end

    it 'properly pops the cassette off the stack even if an error occurs' do
      cassette = insert_cassette
      allow(cassette).to receive(:eject) { raise "boom" }
      expect { VCR.eject_cassette }.to raise_error("boom")
      expect(VCR.current_cassette).to be_nil
    end
  end

  describe '.use_cassette' do
    it 'inserts a new cassette' do
      new_cassette = VCR::Cassette.new(:use_cassette_test)
      expect(VCR).to receive(:insert_cassette).and_return(new_cassette)
      VCR.use_cassette(:cassette_test) { }
    end

    it 'yields' do
      yielded = false
      VCR.use_cassette(:cassette_test, &lambda { yielded = true })
      expect(yielded).to be true
    end

    it 'yields the cassette instance if the block expects an argument' do
      VCR.use_cassette('name', :record => :new_episodes, &lambda do |cassette|
        expect(cassette).to equal(VCR.current_cassette)
      end)
    end

    it 'yields the cassette instance if the block expects a variable number of args' do
      VCR.use_cassette('name', :record => :new_episodes) do |*args|
        expect(args.size).to eq(1)
        expect(args.first).to equal(VCR.current_cassette)
      end
    end

    it 'ejects the cassette' do
      expect(VCR).to receive(:eject_cassette)
      VCR.use_cassette(:cassette_test) { }
    end

    it 'ejects the cassette even if there is an error' do
      expect(VCR).to receive(:eject_cassette)
      test_error = Class.new(StandardError)
      expect { VCR.use_cassette(:cassette_test) { raise test_error } }.to raise_error(test_error)
    end

    it 'does not eject a cassette if there was an error inserting it' do
      expect(VCR).to receive(:insert_cassette).and_raise(StandardError.new('Boom!'))
      expect(VCR).not_to receive(:eject_cassette)
      expect { VCR.use_cassette(:test) { } }.to raise_error(StandardError, 'Boom!')
    end

    it 'raises a helpful error if no block is given' do
      expect {
        VCR.use_cassette(:test)
      }.to raise_error(/requires a block/)
    end
  end

  describe '.http_interactions' do
    it 'returns the current_cassette.http_interactions when there is a current cassette' do
      cassette = VCR.insert_cassette("a cassette")
      expect(VCR.http_interactions).to be(cassette.http_interactions)
    end

    it 'returns a null list when there is no current cassette' do
      expect(VCR.current_cassette).to be_nil
      expect(VCR.http_interactions).to be(VCR::Cassette::HTTPInteractionList::NullList)
    end
  end

  describe '.real_http_connections_allowed?' do
    context 'when a cassette is inserted' do
      it 'returns true if the cassette is recording' do
        VCR.insert_cassette('foo', :record => :all)
        expect(VCR.current_cassette).to be_recording
        expect(VCR.real_http_connections_allowed?).to be true
      end

      it 'returns false if the cassette is not recording' do
        VCR.insert_cassette('foo', :record => :none)
        expect(VCR.current_cassette).not_to be_recording
        expect(VCR.real_http_connections_allowed?).to be false
      end
    end

    context 'when no cassette is inserted' do
      before(:each) do
        expect(VCR.current_cassette).to be_nil
      end

      it 'returns true if the allow_http_connections_when_no_cassette option is set to true' do
        expect(VCR).to be_turned_on
        VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }
        expect(VCR.real_http_connections_allowed?).to be true
      end

      it 'returns true if VCR is turned off' do
        VCR.turn_off!
        VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
        expect(VCR.real_http_connections_allowed?).to be true
      end

      it 'returns false if the allow_http_connections_when_no_cassette option is set to false and VCR is turned on' do
        expect(VCR).to be_turned_on
        VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
        expect(VCR.real_http_connections_allowed?).to be false
      end
    end
  end

  describe '.request_matchers' do
    it 'always returns the same memoized request matcher registry instance' do
      expect(VCR.request_matchers).to be_a(VCR::RequestMatcherRegistry)
      expect(VCR.request_matchers).to be(VCR.request_matchers)
    end
  end

  describe '.request_ignorer' do
    it 'always returns the same memoized request ignorer instance' do
      expect(VCR.request_ignorer).to be_a(VCR::RequestIgnorer)
      expect(VCR.request_ignorer).to be(VCR.request_ignorer)
    end
  end

  describe '.library_hooks' do
    it 'always returns the same memoized LibraryHooks instance' do
      expect(VCR.library_hooks).to be_a(VCR::LibraryHooks)
      expect(VCR.library_hooks).to be(VCR.library_hooks)
    end
  end

  describe '.cassette_serializers' do
    it 'always returns the same memoized cassette serializers instance' do
      expect(VCR.cassette_serializers).to be_a(VCR::Cassette::Serializers)
      expect(VCR.cassette_serializers).to be(VCR.cassette_serializers)
    end
  end

  describe ".cassette_persisters" do
    it "always returns the same memoized Cassette::Persisters instance" do
      expect(VCR.cassette_persisters).to be_a(VCR::Cassette::Persisters)
      expect(VCR.cassette_persisters).to be(VCR.cassette_persisters)
    end
  end

  describe '.configuration' do
    it 'returns the configuration object' do
      expect(VCR.configuration).to be_a(VCR::Configuration)
    end

    it 'memoizes the instance' do
      expect(VCR.configuration).to be(VCR.configuration)
    end
  end

  describe '.configure' do
    it 'yields the configuration object' do
      yielded_object = nil
      VCR.configure do |obj|
        yielded_object = obj
      end
      expect(yielded_object).to eq(VCR.configuration)
    end
  end

  describe '.cucumber_tags' do
    it 'yields a cucumber tags object' do
      yielded_object = nil
      VCR.cucumber_tags do |obj|
        yielded_object = obj
      end
      expect(yielded_object).to be_instance_of(VCR::CucumberTags)
    end
  end

  describe '.record_http_interaction' do
    before(:each) { allow(VCR).to receive(:current_cassette).and_return(current_cassette) }
    let(:interaction) { double(:request => double) }

    context 'when there is not a current cassette' do
      let(:current_cassette) { nil }

      it 'does not record a request' do
        # we can't set a message expectation on nil, but there is no place to record it to...
        # this mostly tests that there is no error.
        VCR.record_http_interaction(interaction)
      end
    end

    context 'when there is a current cassette' do
      let(:current_cassette) { double('current cassette') }

      it 'records the request when it should not be ignored' do
        allow(VCR.request_ignorer).to receive(:ignore?).with(interaction.request).and_return(false)
        expect(current_cassette).to receive(:record_http_interaction).with(interaction)
        VCR.record_http_interaction(interaction)
      end

      it 'does not record the request when it should be ignored' do
        allow(VCR.request_ignorer).to receive(:ignore?).with(interaction.request).and_return(true)
        expect(current_cassette).not_to receive(:record_http_interaction)
        VCR.record_http_interaction(interaction)
      end
    end
  end

  describe '.turn_off!' do
    it 'indicates it is turned off' do
      VCR.turn_off!
      expect(VCR).not_to be_turned_on
    end

    it 'raises an error if a cassette is in use' do
      VCR.insert_cassette('foo')
      expect {
        VCR.turn_off!
      }.to raise_error(VCR::CassetteInUseError, /foo/)
    end

    it 'causes an error to be raised if you insert a cassette while VCR is turned off' do
      VCR.turn_off!
      expect {
        VCR.insert_cassette('foo')
      }.to raise_error(VCR::TurnedOffError)
    end

    it 'raises an ArgumentError when given an invalid option' do
      expect {
        VCR.turn_off!(:invalid_option => true)
      }.to raise_error(ArgumentError)
    end

    context 'when `:ignore_cassettes => true` is passed' do
      before(:each) { VCR.turn_off!(:ignore_cassettes => true) }

      it 'ignores cassette insertions' do
        VCR.insert_cassette('foo')
        expect(VCR.current_cassette).to be_nil
      end

      it 'still runs a block passed to use_cassette' do
        yielded = false

        VCR.use_cassette('foo') do
          yielded = true
          expect(VCR.current_cassette).to be_nil
        end

        expect(yielded).to be true
      end
    end
  end

  describe '.turn_on!' do
    before(:each) { VCR.turn_off! }

    it 'indicates it is turned on' do
      VCR.turn_on!
      expect(VCR).to be_turned_on
    end
  end

  describe '.turned_off' do
    it 'yields with VCR turned off' do
      expect(VCR).to be_turned_on
      yielded = false

      VCR.turned_off do
        yielded = true
        expect(VCR).not_to be_turned_on
      end

      expect(yielded).to eq(true)
      expect(VCR).to be_turned_on
    end

    it 'passes options through to .turn_off!' do
      expect(VCR).to receive(:turn_off!).with(:ignore_cassettes => true)
      VCR.turned_off(:ignore_cassettes => true) { }
    end
  end

  describe '.turned_on?' do
    it 'is on by default' do
      expect(VCR).to be_turned_on
    end
  end
end
