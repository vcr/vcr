require 'spec_helper'

describe VCR::HttpStubbingAdapters::Faraday do
  without_monkey_patches :all

  it_behaves_like 'an http stubbing adapter',
    %w[ faraday-typhoeus faraday-net_http faraday-patron ],
    [:method, :uri, :host, :path, :body, :headers],
    :status_message_not_exposed, :does_not_support_rotating_responses

  it_performs('version checking',
    :valid    => %w[ 0.5.3 0.5.10 ],
    :too_low  => %w[ 0.5.2 0.4.99 ],
    :too_high => %w[ 0.6.0 1.0.0 ]
  ) do
    before(:each) { @orig_version = Faraday::VERSION }
    after(:each)  { Faraday::VERSION = @orig_version }

    # Cannot be regular method def as that raises a "dynamic constant assignment" error
    define_method :stub_version do |version|
      ::Faraday::VERSION = version
    end
  end

  context 'when some request have been stubbed' do
    subject { described_class }
    let(:request_1) { VCR::Request.new(:get, 'http://foo.com') }
    let(:request_2) { VCR::Request.new(:get, 'http://bazz.com') }
    let(:match_attributes) { [:method, :uri] }

    def stubbed_response_for(request)
      matcher = VCR::RequestMatcher.new(request, match_attributes)
      subject.stubbed_response_for(matcher)
    end

    before(:each) do
      subject.stub_requests(
        [
          VCR::HTTPInteraction.new(request_1, :response_1),
          VCR::HTTPInteraction.new(request_1, :response_2),
        ], match_attributes
      )
    end

    def test_stubbed_responses
      stubbed_response_for(request_1).should == :response_1
      stubbed_response_for(request_1).should == :response_2
      stubbed_response_for(request_1).should == :response_2
      stubbed_response_for(request_1).should == :response_2
    end

    describe '.stubbed_response_for' do
      it 'returns nil when there is no matching response' do
        stubbed_response_for(request_2).should be_nil
      end

      it 'dequeues each response and continues to return the last one' do
        test_stubbed_responses
      end
    end

    describe '.restore_stubs_checkpoints' do
      let(:cassette_1) { VCR::Cassette.new('1') }

      before(:each) do
        subject.create_stubs_checkpoint(cassette_1)
      end

      it 'restores the queues to the checkpoint state when a queue has additional responses' do
        subject.stub_requests( [
          VCR::HTTPInteraction.new(request_1, :response_3),
        ], match_attributes)

        subject.restore_stubs_checkpoint(cassette_1)
        test_stubbed_responses
      end

      it 'restores the queues to the checkpoint state when a queue has been used' do
        stubbed_response_for(request_1)
        subject.restore_stubs_checkpoint(cassette_1)
        test_stubbed_responses
      end
    end
  end
end
