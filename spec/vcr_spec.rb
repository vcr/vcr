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
      new_cassette.should_not eq(orig_cassette)
      VCR.current_cassette.should eq(new_cassette)
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
      VCR.eject_cassette.should eq(cassette)
    end

    it 'returns the #current_cassette to the previous one' do
      cassette1, cassette2 = insert_cassette(:foo1), insert_cassette(:foo2)
      expect { VCR.eject_cassette }.to change(VCR, :current_cassette).from(cassette2).to(cassette1)
    end

    it 'keeps the cassette as the current one until after #eject has finished' do
      cassette = insert_cassette
      current = nil
      cassette.stub(:eject) { current = VCR.current_cassette }

      VCR.eject_cassette

      current.should be(cassette)
      VCR.current_cassette.should_not be(cassette)
    end

    it 'properly pops the cassette off the stack even if an error occurs' do
      cassette = insert_cassette
      cassette.stub(:eject) { raise "boom" }
      expect { VCR.eject_cassette }.to raise_error("boom")
      VCR.current_cassette.should be_nil
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
        args.size.should eq(1)
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

    it 'raises a helpful error if no block is given' do
      expect {
        VCR.use_cassette(:test)
      }.to raise_error(/requires a block/)
    end
  end

  describe '.http_interactions' do
    it 'returns the current_cassette.http_interactions when there is a current cassette' do
      cassette = VCR.insert_cassette("a cassette")
      VCR.http_interactions.should be(cassette.http_interactions)
    end

    it 'returns a null list when there is no current cassette' do
      VCR.current_cassette.should be_nil
      VCR.http_interactions.should be(VCR::Cassette::HTTPInteractionList::NullList)
    end
  end

  describe '.real_http_connections_allowed?' do
    context 'when a cassette is inserted' do
      it 'returns true if the cassette is recording' do
        VCR.insert_cassette('foo', :record => :all)
        VCR.current_cassette.should be_recording
        VCR.real_http_connections_allowed?.should be_true
      end

      it 'returns false if the cassette is not recording' do
        VCR.insert_cassette('foo', :record => :none)
        VCR.current_cassette.should_not be_recording
        VCR.real_http_connections_allowed?.should be_false
      end
    end

    context 'when no cassette is inserted' do
      before(:each) { VCR.current_cassette.should be_nil }

      it 'returns true if the allow_http_connections_when_no_cassette option is set to true' do
        VCR.should be_turned_on
        VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }
        VCR.real_http_connections_allowed?.should be_true
      end

      it 'returns true if VCR is turned off' do
        VCR.turn_off!
        VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
        VCR.real_http_connections_allowed?.should be_true
      end

      it 'returns false if the allow_http_connections_when_no_cassette option is set to false and VCR is turned on' do
        VCR.should be_turned_on
        VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
        VCR.real_http_connections_allowed?.should be_false
      end
    end
  end

  describe '.request_matchers' do
    it 'always returns the same memoized request matcher registry instance' do
      VCR.request_matchers.should be_a(VCR::RequestMatcherRegistry)
      VCR.request_matchers.should be(VCR.request_matchers)
    end
  end

  describe '.request_ignorer' do
    it 'always returns the same memoized request ignorer instance' do
      VCR.request_ignorer.should be_a(VCR::RequestIgnorer)
      VCR.request_ignorer.should be(VCR.request_ignorer)
    end
  end

  describe '.library_hooks' do
    it 'always returns the same memoized LibraryHooks instance' do
      VCR.library_hooks.should be_a(VCR::LibraryHooks)
      VCR.library_hooks.should be(VCR.library_hooks)
    end
  end

  describe '.cassette_serializers' do
    it 'always returns the same memoized cassette serializers instance' do
      VCR.cassette_serializers.should be_a(VCR::Cassette::Serializers)
      VCR.cassette_serializers.should be(VCR.cassette_serializers)
    end
  end

  describe ".cassette_persisters" do
    it "always returns the same memoized Cassette::Persisters instance" do
      VCR.cassette_persisters.should be_a(VCR::Cassette::Persisters)
      VCR.cassette_persisters.should be(VCR.cassette_persisters)
    end
  end

  describe '.configuration' do
    it 'returns the configuration object' do
      VCR.configuration.should be_a(VCR::Configuration)
    end

    it 'memoizes the instance' do
      VCR.configuration.should be(VCR.configuration)
    end
  end

  describe '.configure' do
    it 'yields the configuration object' do
      yielded_object = nil
      VCR.configure do |obj|
        yielded_object = obj
      end
      yielded_object.should eq(VCR.configuration)
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

  describe '.record_http_interaction' do
    before(:each) { VCR.stub(:current_cassette => current_cassette) }
    let(:interaction) { stub(:request => stub) }

    context 'when there is not a current cassette' do
      let(:current_cassette) { nil }

      it 'does not record a request' do
        # we can't set a message expectation on nil, but there is no place to record it to...
        # this mostly tests that there is no error.
        VCR.record_http_interaction(interaction)
      end
    end

    context 'when there is a current cassette' do
      let(:current_cassette) { mock('current cassette') }

      it 'records the request when it should not be ignored' do
        VCR.request_ignorer.stub(:ignore?).with(interaction.request).and_return(false)
        current_cassette.should_receive(:record_http_interaction).with(interaction)
        VCR.record_http_interaction(interaction)
      end

      it 'does not record the request when it should be ignored' do
        VCR.request_ignorer.stub(:ignore?).with(interaction.request).and_return(true)
        current_cassette.should_not_receive(:record_http_interaction)
        VCR.record_http_interaction(interaction)
      end
    end
  end

  describe '.turn_off!' do
    it 'indicates it is turned off' do
      VCR.turn_off!
      VCR.should_not be_turned_on
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
        VCR.current_cassette.should be_nil
      end

      it 'still runs a block passed to use_cassette' do
        yielded = false

        VCR.use_cassette('foo') do
          yielded = true
          VCR.current_cassette.should be_nil
        end

        yielded.should be_true
      end
    end
  end

  describe '.turn_on!' do
    before(:each) { VCR.turn_off! }

    it 'indicates it is turned on' do
      VCR.turn_on!
      VCR.should be_turned_on
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

      yielded.should eq(true)
      VCR.should be_turned_on
    end

    it 'passes options through to .turn_off!' do
      VCR.should_receive(:turn_off!).with(:ignore_cassettes => true)
      VCR.turned_off(:ignore_cassettes => true) { }
    end
  end

  describe '.turned_on?' do
    it 'is on by default' do
      VCR.send(:initialize_ivars) # clear internal state
      VCR.should be_turned_on
    end
  end
end
