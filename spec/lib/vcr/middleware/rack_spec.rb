require 'spec_helper'
require 'vcr/middleware/rack'

module VCR
  module Middleware
    describe CassetteArguments do
      describe '#name' do
        it 'initially returns nil' do
          expect(subject.name).to be_nil
        end

        it 'stores the given value, returning it when no arg is given' do
          subject.name :value1
          expect(subject.name).to eq(:value1)

          subject.name :value2
          expect(subject.name).to eq(:value2)
        end
      end

      describe '#options' do
        it 'initially returns an empty hash' do
          expect(subject.options).to eq({})
        end

        it 'merges the given hash options, returning them when no arg is given' do
          subject.options :record => :new_episodes
          expect(subject.options).to eq({ :record => :new_episodes })

          subject.options :erb => true
          expect(subject.options).to eq({ :record => :new_episodes, :erb => true })
        end
      end
    end

    describe Rack do
      describe '.new' do
        it 'raises an error if no cassette arguments block is provided' do
          expect {
            described_class.new(lambda { |env| })
          }.to raise_error(ArgumentError)
        end
      end

      describe '#call' do
        let(:env_hash) { { :env => :hash } }
        it 'calls the provided rack app and returns its response' do
          rack_app = double
          expect(rack_app).to receive(:call).with(env_hash).and_return(:response)
          instance = described_class.new(rack_app) { |c| c.name 'cassette_name' }
          expect(instance.call(env_hash)).to eq(:response)
        end

        it 'uses a cassette when the rack app is called' do
          expect(VCR.current_cassette).to be_nil
          rack_app = lambda { |env| expect(VCR.current_cassette).not_to be_nil }
          instance = described_class.new(rack_app) { |c| c.name 'cassette_name' }
          instance.call({})
          expect(VCR.current_cassette).to be_nil
        end

        it 'sets the cassette name based on the provided block' do
          rack_app = lambda do |env|
            expect(VCR.current_cassette.name).to eq('rack_cassette')
          end
          instance = described_class.new(rack_app) { |c| c.name 'rack_cassette' }
          instance.call({})
        end

        it 'sets the cassette options based on the provided block' do
          rack_app = lambda do |env|
            expect(VCR.current_cassette.erb).to eq({ :foo => :bar })
          end

          instance = described_class.new(rack_app, &lambda do |c|
            c.name    'c'
            c.options :erb => { :foo => :bar }
          end)

          instance.call({})
        end

        it 'yields the rack env to the provided block when the block accepts 2 arguments' do
          instance = described_class.new(lambda { |env| }, &lambda do |c, env|
            expect(env).to eq(env_hash)
            c.name    'c'
          end)

          instance.call(env_hash)
        end
      end

      let(:threaded_app) do
        lambda do |env|
          sleep 0.15
          expect(VCR.send(:cassettes).size).to eq(1)
          [200, {}, ['OK']]
        end
      end

      it 'is thread safe' do
        stack = described_class.new(threaded_app) do |cassette|
          cassette.name 'c'
        end

        thread = Thread.new { stack.call({}) }
        stack.call({})
        thread.join

        expect(VCR.current_cassette).to be_nil
      end
    end
  end
end

