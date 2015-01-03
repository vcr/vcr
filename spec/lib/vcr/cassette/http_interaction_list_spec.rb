require 'vcr/util/logger'
require 'vcr/cassette/http_interaction_list'
require 'vcr/request_matcher_registry'
require 'vcr/structs'
require 'support/configuration_stubbing'

module VCR
  class Cassette
    describe HTTPInteractionList do
      include_context "configuration stubbing"

      ::RSpec::Matchers.define :respond_with do |expected|
        match { |a| expected.nil? ? a.nil? : a.body == expected }
      end

      before(:each) do
        allow(VCR).to receive(:request_matchers).and_return(VCR::RequestMatcherRegistry.new)
        allow(config).to receive(:logger).and_return(double.as_null_object)
      end

      def request_with(values)
        VCR::Request.new.tap do |request|
          values.each do |name, value|
            request.send("#{name}=", value)
          end
        end
      end

      def response(body)
        VCR::Response.new.tap do |r|
          r.body = body
          r.status = VCR::ResponseStatus.new(200)
        end
      end

      def interaction(body, request_values)
        VCR::HTTPInteraction.new \
          request_with(request_values),
          response(body)
      end

      let(:original_list_array) do [
        interaction('put response', :method => :put),
        interaction('post response 1', :method => :post),
        interaction('post response 2', :method => :post)
      ] end

      let(:allow_playback_repeats) { false } # the default
      let(:list) { HTTPInteractionList.new(original_list_array, [:method], allow_playback_repeats) }

      describe "#has_used_interaction_matching?" do
        it 'returns false when no interactions have been used' do
          expect(list).not_to have_used_interaction_matching(request_with(:method => :put))
        end

        it 'returns true when there is a matching used interaction (even if there is also an unused one that matches)' do
          list.response_for(request_with(:method => :post))
          expect(list).to have_used_interaction_matching(request_with(:method => :post))
        end

        it 'returns false when none of the used interactions match' do
          list.response_for(request_with(:method => :put))
          expect(list).not_to have_used_interaction_matching(request_with(:method => :post))
        end
      end

      describe "#remaining_unused_interaction_count" do
        it 'returns the number of unused interactions' do
          expect(list.remaining_unused_interaction_count).to eq(3)

          list.response_for(request_with(:method => :get))
          expect(list.remaining_unused_interaction_count).to eq(3)

          list.response_for(request_with(:method => :put))
          expect(list.remaining_unused_interaction_count).to eq(2)

          list.response_for(request_with(:method => :put))
          expect(list.remaining_unused_interaction_count).to eq(2)

          list.response_for(request_with(:method => :post))
          expect(list.remaining_unused_interaction_count).to eq(1)

          list.response_for(request_with(:method => :post))
          expect(list.remaining_unused_interaction_count).to eq(0)

          list.response_for(request_with(:method => :post))
          expect(list.remaining_unused_interaction_count).to eq(0)
        end
      end

      describe "#assert_no_unused_interactions?" do
        it 'should raise a SkippedHTTPRequestError when there are unused interactions left' do
          expect {
            list.assert_no_unused_interactions!
          }.to raise_error(Errors::UnusedHTTPInteractionError)

          list.response_for(request_with(:method => :put))
          expect {
            list.assert_no_unused_interactions!
          }.to raise_error(Errors::UnusedHTTPInteractionError)
        end

        it 'should raise nothing when there are no unused interactions left' do
          [:put, :post, :post].each do |method|
            list.response_for(request_with(:method => method))
          end

          expect {
            list.assert_no_unused_interactions!
          }.not_to raise_error
        end

        context 'when the null logger is in use' do
          before { allow(config).to receive(:logger).and_return(Logger::Null) }

          it 'includes formatted request details in the error message' do
            expect {
              list.assert_no_unused_interactions!
            }.to raise_error(/\[put/)
          end

          it 'includes formatted response details in the error message' do
            expect {
              list.assert_no_unused_interactions!
            }.to raise_error(/\[200 "put response"\]/)
          end
        end
      end

      describe "has_interaction_matching?" do
        it 'returns false when the list is empty' do
          expect(HTTPInteractionList.new([], [:method])).not_to have_interaction_matching(double)
        end

        it 'returns false when there is no matching interaction' do
          expect(list).not_to have_interaction_matching(request_with(:method => :get))
        end

        it 'returns true when there is a matching interaction' do
          expect(list).to have_interaction_matching(request_with(:method => :post))
        end

        it 'does not consume the interactions when they match' do
          expect(list).to have_interaction_matching(request_with(:method => :post))
          expect(list.remaining_unused_interaction_count).to eq(3)
          expect(list).to have_interaction_matching(request_with(:method => :post))
          expect(list.remaining_unused_interaction_count).to eq(3)
        end

        it 'invokes each matcher block to find the matching interaction' do
          VCR.request_matchers.register(:foo) { |r1, r2| true }
          VCR.request_matchers.register(:bar) { |r1, r2| true }

          calls = 0
          VCR.request_matchers.register(:baz) { |r1, r2| calls += 1; calls == 2 }

          list = HTTPInteractionList.new([
            interaction('response', :method => :put)
          ], [:foo, :bar, :baz])

          expect(list).not_to have_interaction_matching(request_with(:method => :post))
          expect(list).to     have_interaction_matching(request_with(:method => :post))
        end

        it "delegates to the parent list when it can't find a matching interaction" do
          parent_list = double(:has_interaction_matching? => true)
          expect(HTTPInteractionList.new( [], [:method], false, parent_list)).to have_interaction_matching(double)
          parent_list = double(:has_interaction_matching? => false)
          expect(HTTPInteractionList.new( [], [:method], false, parent_list)).not_to have_interaction_matching(double)
        end

        context 'when allow_playback_repeats is set to true' do
          let(:allow_playback_repeats) { true }

          it 'considers used interactions' do
            list.response_for(request_with(:method => :put))

            results = 10.times.map do
              list.has_interaction_matching?(request_with(:method => :put))
            end

            expect(results).to eq([true] * 10)
          end
        end

        context 'when allow_playback_repeats is set to false' do
          let(:allow_playback_repeats) { false }

          it 'does not consider used interactions' do
            list.response_for(request_with(:method => :put))

            result = 10.times.map do
              list.has_interaction_matching?(request_with(:method => :put))
            end

            expect(result).to eq([false] * 10)
          end
        end
      end

      describe "#response_for" do
        it 'returns nil when the list is empty' do
          expect(HTTPInteractionList.new([], [:method]).response_for(double)).to respond_with(nil)
        end

        it 'returns nil when there is no matching interaction' do
          response = HTTPInteractionList.new([
            interaction('foo', :method => :post),
            interaction('foo', :method => :put)
          ], [:method]).response_for(
            request_with(:method => :get)
          )

          expect(response).to respond_with(nil)
        end

        it 'returns the first matching interaction' do
          list = HTTPInteractionList.new([
            interaction('put response', :method => :put),
            interaction('post response 1', :method => :post),
            interaction('post response 2', :method => :post)
          ], [:method])

          expect(list.response_for(request_with(:method => :post))).to respond_with("post response 1")
        end

        it 'invokes each matcher block to find the matching interaction' do
          VCR.request_matchers.register(:foo) { |r1, r2| true }
          VCR.request_matchers.register(:bar) { |r1, r2| true }

          calls = 0
          VCR.request_matchers.register(:baz) { |r1, r2| calls += 1; calls == 2 }

          list = HTTPInteractionList.new([
            interaction('response', :method => :put)
          ], [:foo, :bar, :baz])

          expect(list.response_for(request_with(:method => :post))).to respond_with(nil)
          expect(list.response_for(request_with(:method => :post))).to respond_with('response')
        end

        it "delegates to the parent list when it can't find a matching interaction" do
          parent_list = double(:response_for => response('parent'))
          result = HTTPInteractionList.new(
            [], [:method], false, parent_list
          ).response_for(double)

          expect(result).to respond_with('parent')
        end

        it 'consumes the first matching interaction so that it will not be used again' do
          expect(list.response_for(request_with(:method => :post)).body).to eq("post response 1")
          expect(list.response_for(request_with(:method => :post)).body).to eq("post response 2")
        end

        context 'when allow_playback_repeats is set to true' do
          let(:allow_playback_repeats) { true }

          it 'continues to return the response from the last matching interaction when there are no more' do
            list.response_for(request_with(:method => :post))

            results = 10.times.map do
              response = list.response_for(request_with(:method => :post))
              response ? response.body : nil
            end

            expect(results).to eq(["post response 2"] * 10)
          end
        end

        context 'when allow_playback_repeats is set to false' do
          let(:allow_playback_repeats) { false }

          it 'returns nil when there are no more unused interactions' do
            list.response_for(request_with(:method => :post))
            list.response_for(request_with(:method => :post))

            results = 10.times.map do
              list.response_for(request_with(:method => :post))
            end

            expect(results).to eq([nil] * 10)
          end
        end

        it 'does not modify the original interaction array the list was initialized with' do
          original_dup = original_list_array.dup
          list.response_for(request_with(:method => :post))
          expect(original_list_array).to eq original_dup
        end
      end
    end
  end
end

