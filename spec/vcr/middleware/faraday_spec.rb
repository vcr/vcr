require 'spec_helper'

describe VCR::Middleware::Faraday do
  describe '.new' do
    it 'raises an error if no cassette arguments block is provided' do
      expect {
        described_class.new(lambda { |env| })
      }.to raise_error(ArgumentError)
    end
  end

  describe '#call' do
    let(:env_hash) { { :url => 'http://localhost:3000/' } }

    before(:each) do
      VCR::HttpStubbingAdapters::Faraday.ignored_hosts = ['localhost']
    end

    it 'uses a cassette when the app is called' do
      VCR.current_cassette.should be_nil
      app = lambda { |env| VCR.current_cassette.should_not be_nil }
      instance = described_class.new(app) { |c| c.name 'cassette_name' }
      instance.call(env_hash)
      VCR.current_cassette.should be_nil
    end

    it 'sets the cassette name based on the provided block' do
      app = lambda { |env| VCR.current_cassette.name.should == 'rack_cassette' }
      instance = described_class.new(app) { |c| c.name 'rack_cassette' }
      instance.call(env_hash)
    end

    it 'sets the cassette options based on the provided block' do
      app = lambda { |env| VCR.current_cassette.erb.should == { :foo => :bar } }
      instance = described_class.new(app) do |c|
        c.name    'c'
        c.options :erb => { :foo => :bar }
      end

      instance.call(env_hash)
    end

    it 'yields the env to the provided block when the block accepts 2 arguments' do
      instance = described_class.new(lambda { |env| }) do |c, env|
        env.should == env_hash
        c.name    'c'
      end

      instance.call(env_hash)
    end
  end
end
