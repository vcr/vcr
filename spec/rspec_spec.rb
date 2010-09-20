require 'spec_helper'
require 'vcr/rspec'

describe VCR::RSpec::Macros do
  extend described_class

  describe '#use_vcr_cassette' do
    def self.perform_test(context_name, expected_cassette_name, *args, &block)
      context context_name do
        after(:each) do
          if @test_ejection
            VCR.current_cassette.should be_nil
          end
        end

        use_vcr_cassette *args

        it 'ejects the cassette in an after hook' do
          VCR.current_cassette.should be_a(VCR::Cassette)
          @test_ejection = true
        end

        it "creates a cassette named '#{expected_cassette_name}" do
          VCR.current_cassette.name.should == expected_cassette_name
        end

        module_eval(&block) if block
      end
    end

    perform_test 'when called with an explicit name', 'explicit_name', 'explicit_name'

    perform_test 'when called with an explicit name and some options', 'explicit_name', 'explicit_name', :match_requests_on => [:method, :host] do
      it 'uses the provided cassette options' do
        VCR.current_cassette.match_requests_on.should == [:method, :host]
      end
    end

    perform_test 'when called with nothing', 'VCR::RSpec::Macros/#use_vcr_cassette/when called with nothing'

    perform_test 'when called with some options', 'VCR::RSpec::Macros/#use_vcr_cassette/when called with some options', :match_requests_on => [:method, :host] do
      it 'uses the provided cassette options' do
        VCR.current_cassette.match_requests_on.should == [:method, :host]
      end
    end
  end
end
