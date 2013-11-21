require 'spec_helper'

VCR.configuration.configure_rspec_metadata!

describe VCR::RSpec::Metadata, :skip_vcr_reset do
  before(:all) { VCR.reset! }
  after(:each) { VCR.reset! }

  context 'an example group', :vcr do
    context 'with a nested example group' do
      it 'uses a cassette for any examples' do
        expect(VCR.current_cassette.name.split('/')).to eq([
          'VCR::RSpec::Metadata',
          'an example group',
          'with a nested example group',
          'uses a cassette for any examples'
        ])
      end
    end
  end

  context 'with the cassette name overridden at the example group level', :vcr => { :cassette_name => 'foo' } do
    it 'overrides the cassette name for an example' do
      expect(VCR.current_cassette.name).to eq('foo')
    end

    it 'overrides the cassette name for another example' do
      expect(VCR.current_cassette.name).to eq('foo')
    end
  end

  it 'allows the cassette name to be overriden', :vcr => { :cassette_name => 'foo' } do
    expect(VCR.current_cassette.name).to eq('foo')
  end

  it 'allows the cassette options to be set', :vcr => { :match_requests_on => [:method] } do
    expect(VCR.current_cassette.match_requests_on).to eq([:method])
  end
end

describe VCR::RSpec::Macros do
  extend described_class

  describe '#use_vcr_cassette' do
    def self.perform_test(context_name, expected_cassette_name, *args, &block)
      context context_name do
        after(:each) do |example|
          if example.metadata[:test_ejection]
            expect(VCR.current_cassette).to be_nil
          end
        end

        use_vcr_cassette(*args)

        it 'ejects the cassette in an after hook', :test_ejection do
          expect(VCR.current_cassette).to be_a(VCR::Cassette)
        end

        it "creates a cassette named '#{expected_cassette_name}" do
          expect(VCR.current_cassette.name).to eq(expected_cassette_name)
        end

        module_eval(&block) if block
      end
    end

    perform_test 'when called with an explicit name', 'explicit_name', 'explicit_name'

    perform_test 'when called with an explicit name and some options', 'explicit_name', 'explicit_name', :match_requests_on => [:method, :host] do
      it 'uses the provided cassette options' do
        expect(VCR.current_cassette.match_requests_on).to eq([:method, :host])
      end
    end

    perform_test 'when called with nothing', 'VCR::RSpec::Macros/#use_vcr_cassette/when called with nothing'

    perform_test 'when called with some options', 'VCR::RSpec::Macros/#use_vcr_cassette/when called with some options', :match_requests_on => [:method, :host] do
      it 'uses the provided cassette options' do
        expect(VCR.current_cassette.match_requests_on).to eq([:method, :host])
      end
    end
  end
end
