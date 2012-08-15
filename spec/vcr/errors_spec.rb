require 'spec_helper'

module VCR
  module Errors
    describe UnhandledHTTPRequestError do
      def message_for(request_values = {})
        described_class.new(request_with request_values).message
      end
      alias message message_for

      def request_with(values)
        VCR::Request.new.tap do |request|
          values.each do |name, value|
            request.send("#{name}=", value)
          end
        end
      end

      it 'identifies the request by method and URI' do
        message_for(:method => :post, :uri => 'http://foo.com/').should include(
          'POST http://foo.com/'
        )
      end

      context 'when there is no current cassette' do
        it 'mentions that there is no current cassette' do
          message.should include('There is currently no cassette in use.')
        end

        it 'mentions that the request can be recorded by inserting a cassette' do
          message.should match(/record this request and play it back.*VCR.use_cassette/m)
        end

        it 'mentions the allow_http_connections_when_no_cassette option' do
          message.should include('allow_http_connections_when_no_cassette')
        end

        it 'mentions that the request can be ignored' do
          message.should include('set an `ignore_request` callback')
        end

        it 'does not double-insert the asterisks for the bullet points' do
          message.should_not match(/\s+\*\s+\*/)
        end

        it 'mentions the debug logging configuration option' do
          message.should include('debug_logger')
        end
      end

      context 'when there is a current cassette' do
        it 'mentions the details about the current casette' do
          VCR.use_cassette('example') do
            message.should match(/VCR is currently using the following cassette:.+example.yml/m)
          end
        end

        it 'mentions that :new_episodes can be used to record the request' do
          VCR.use_cassette('example') do
            message.should include('use the :new_episodes record mode')
          end
        end

        it 'mentions that :once does not allow a cassette to be re-recorded' do
          VCR.use_cassette('example', :record => :once) do
            message.should include('(:once) does not allow new requests to be recorded')
          end
        end

        it 'mentions that :none does not allow any recording' do
          VCR.use_cassette('example', :record => :none) do
            message.should include('(:none) does not allow requests to be recorded')
          end
        end

        it 'does not mention the :once or :none record modes if using the :new_episodes record mode' do
          VCR.use_cassette('example', :record => :new_episodes) do
            message.should_not include(':once', ':none')
          end
        end

        it 'mentions :allow_playback_repeats if the current cassette has a used matching interaction' do
          VCR.use_cassette('example') do |cassette|
            cassette.http_interactions.should respond_to(:has_used_interaction_matching?)
            cassette.http_interactions.stub(:has_used_interaction_matching? => true)
            message.should include('allow_playback_repeats')
          end
        end

        it 'does not mention :allow_playback_repeats if the current cassette does not have a used matching interaction' do
          VCR.use_cassette('example') do |cassette|
            cassette.http_interactions.should respond_to(:has_used_interaction_matching?)
            cassette.http_interactions.stub(:has_used_interaction_matching? => false)
            message.should_not include('allow_playback_repeats')
          end
        end

        it 'does not mention using a different :match_requests_on option when there are no remaining unused interactions' do
          VCR.use_cassette('example') do |cassette|
            cassette.http_interactions.should respond_to(:remaining_unused_interaction_count)
            cassette.http_interactions.stub(:remaining_unused_interaction_count => 0)
            message.should_not include('match_requests_on cassette option')
          end
        end

        it 'mentions using a different :match_requests_on option when there are some remaining unused interactions' do
          VCR.use_cassette('example') do |cassette|
            cassette.http_interactions.should respond_to(:remaining_unused_interaction_count)
            cassette.http_interactions.stub(:remaining_unused_interaction_count => 1)
            message.should include('match_requests_on cassette option')
          end
        end

        it 'uses the singular (HTTP interaction) when there is only 1 left' do
          VCR.use_cassette('example') do |cassette|
            cassette.http_interactions.should respond_to(:remaining_unused_interaction_count)
            cassette.http_interactions.stub(:remaining_unused_interaction_count => 1)
            message.should include('1 HTTP interaction ')
          end
        end

        it 'uses the plural (HTTP interactions) when there is more than 1 left' do
          VCR.use_cassette('example') do |cassette|
            cassette.http_interactions.should respond_to(:remaining_unused_interaction_count)
            cassette.http_interactions.stub(:remaining_unused_interaction_count => 2)
            message.should include('2 HTTP interactions ')
          end
        end

        it 'mentions the debug logging configuration option' do
          VCR.use_cassette('example', :record => :new_episodes) do
            message.should include('debug_logger')
          end
        end
      end
    end
  end
end

