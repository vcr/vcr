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
        expect(message_for(:method => :post, :uri => 'http://foo.com/')).to include(
          'POST http://foo.com/'
        )
      end

      context 'when there is no current cassette' do
        it 'identifies the request by its body when the default_cassette_options include the body in the match_requests_on option' do
          VCR.configuration.default_cassette_options[:match_requests_on] = [:body]

          expect(message_for(:body => 'param=val1')).to include(
            "Body: param=val1"
          )
        end

        it 'mentions that there is no current cassette' do
          expect(message).to include('There is currently no cassette in use.')
        end

        it 'mentions that the request can be recorded by inserting a cassette' do
          expect(message).to match(/record this request and play it back.*VCR.use_cassette/m)
        end

        it 'mentions the allow_http_connections_when_no_cassette option' do
          expect(message).to include('allow_http_connections_when_no_cassette')
        end

        it 'mentions that the request can be ignored' do
          expect(message).to include('set an `ignore_request` callback')
        end

        it 'does not double-insert the asterisks for the bullet points' do
          expect(message).not_to match(/\s+\*\s+\*/)
        end

        it 'mentions the debug logging configuration option' do
          expect(message).to include('debug_logger')
        end
      end

      context 'when there is a current cassette' do
        it 'identifies the request by its body when the match_requests_on option includes the body' do
          VCR.use_cassette('example', :match_requests_on => [:body]) do
            expect(message_for(:body => 'param=val1')).to include(
              "Body: param=val1"
            )
          end
        end

        it 'does not identify the request by its body when the cassette match_requests_on option does not include the body but the default_cassette_options do' do
          VCR.configuration.default_cassette_options[:match_requests_on] = [:body]
          VCR.use_cassette('example', :match_requests_on => [:uri]) do
            expect(message_for(:body => 'param=val1')).to_not match(/body/i)
          end
        end

        it 'mentions the details about the current casette' do
          VCR.use_cassette('example') do
            expect(message).to match(/VCR is currently using the following cassette:.+example.yml/m)
          end
        end

        it 'mentions that :new_episodes can be used to record the request' do
          VCR.use_cassette('example') do
            expect(message).to include('use the :new_episodes record mode')
          end
        end

        it 'mentions that :once does not allow a cassette to be re-recorded' do
          VCR.use_cassette('example', :record => :once) do
            expect(message).to include('(:once) does not allow new requests to be recorded')
          end
        end

        it 'mentions that :none does not allow any recording' do
          VCR.use_cassette('example', :record => :none) do
            expect(message).to include('(:none) does not allow requests to be recorded')
          end
        end

        it 'does not mention the :once or :none record modes if using the :new_episodes record mode' do
          VCR.use_cassette('example', :record => :new_episodes) do
            expect(message).not_to include(':once', ':none')
          end
        end

        it 'mentions :allow_playback_repeats if the current cassette has a used matching interaction' do
          VCR.use_cassette('example') do |cassette|
            expect(cassette.http_interactions).to respond_to(:has_used_interaction_matching?)
            allow(cassette.http_interactions).to receive(:has_used_interaction_matching?).and_return(true)
            expect(message).to include('allow_playback_repeats')
          end
        end

        it 'does not mention :allow_playback_repeats if the current cassette does not have a used matching interaction' do
          VCR.use_cassette('example') do |cassette|
            expect(cassette.http_interactions).to respond_to(:has_used_interaction_matching?)
            allow(cassette.http_interactions).to receive(:has_used_interaction_matching?).and_return(false)
            expect(message).not_to include('allow_playback_repeats')
          end
        end

        it 'does not mention using a different :match_requests_on option when there are no remaining unused interactions' do
          VCR.use_cassette('example') do |cassette|
            expect(cassette.http_interactions).to respond_to(:remaining_unused_interaction_count)
            allow(cassette.http_interactions).to receive(:remaining_unused_interaction_count).and_return(0)
            expect(message).not_to include('match_requests_on cassette option')
          end
        end

        it 'mentions using a different :match_requests_on option when there are some remaining unused interactions' do
          VCR.use_cassette('example') do |cassette|
            expect(cassette.http_interactions).to respond_to(:remaining_unused_interaction_count)
            allow(cassette.http_interactions).to receive(:remaining_unused_interaction_count).and_return(1)
            expect(message).to include('match_requests_on cassette option')
          end
        end

        it 'uses the singular (HTTP interaction) when there is only 1 left' do
          VCR.use_cassette('example') do |cassette|
            expect(cassette.http_interactions).to respond_to(:remaining_unused_interaction_count)
            allow(cassette.http_interactions).to receive(:remaining_unused_interaction_count).and_return(1)
            expect(message).to include('1 HTTP interaction ')
          end
        end

        it 'uses the plural (HTTP interactions) when there is more than 1 left' do
          VCR.use_cassette('example') do |cassette|
            expect(cassette.http_interactions).to respond_to(:remaining_unused_interaction_count)
            allow(cassette.http_interactions).to receive(:remaining_unused_interaction_count).and_return(2)
            expect(message).to include('2 HTTP interactions ')
          end
        end

        it 'mentions the debug logging configuration option' do
          VCR.use_cassette('example', :record => :new_episodes) do
            expect(message).to include('debug_logger')
          end
        end
      end
    end
  end
end

