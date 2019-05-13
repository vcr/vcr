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

    context 'when the spec has no description' do
      it do
        expect(VCR.current_cassette.name.split('/')).to eq([
          'VCR::RSpec::Metadata',
          'an example group',
          'when the spec has no description',
          '1:1:2:1'
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
