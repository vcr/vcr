require 'vcr/util/logger'
require 'vcr/cassette/http_interaction_list'
require 'vcr/request_matcher_registry'
require 'vcr/structs'

module VCR
  class Cassette
    describe HTTPInteractionList do
      ::RSpec::Matchers.define :respond_with do |expected|
        match { |a| expected.nil? ? a.nil? : a.body == expected }
      end

      before(:each) do
        VCR.stub(:request_matchers => VCR::RequestMatcherRegistry.new)
        VCR.stub_chain(:configuration, :debug_logger).and_return(stub.as_null_object)
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
          list.should_not have_used_interaction_matching(request_with(:method => :put))
        end

        it 'returns true when there is a matching used interaction (even if there is also an unused one that matches)' do
          list.response_for(request_with(:method => :post))
          list.should have_used_interaction_matching(request_with(:method => :post))
        end

        it 'returns false when none of the used interactions match' do
          list.response_for(request_with(:method => :put))
          list.should_not have_used_interaction_matching(request_with(:method => :post))
        end
      end

      describe "#remaining_unused_interaction_count" do
        it 'returns the number of unused interactions' do
          list.remaining_unused_interaction_count.should eq(3)

          list.response_for(request_with(:method => :get))
          list.remaining_unused_interaction_count.should eq(3)

          list.response_for(request_with(:method => :put))
          list.remaining_unused_interaction_count.should eq(2)

          list.response_for(request_with(:method => :put))
          list.remaining_unused_interaction_count.should eq(2)

          list.response_for(request_with(:method => :post))
          list.remaining_unused_interaction_count.should eq(1)

          list.response_for(request_with(:method => :post))
          list.remaining_unused_interaction_count.should eq(0)

          list.response_for(request_with(:method => :post))
          list.remaining_unused_interaction_count.should eq(0)
        end
      end

      describe "#assert_no_unused_interactions?" do
        it 'should raise a SkippedHTTPRequestError when there are unused interactions left' do
           expect { list.assert_no_unused_interactions! }.to raise_error(Errors::UnusedHTTPInteractionError)
           list.response_for(request_with(:method => :put))
           expect { list.assert_no_unused_interactions! }.to raise_error(Errors::UnusedHTTPInteractionError)
        end

        it 'should raise nothing when there are no unused interactions left' do
          [:put, :post, :post].each do |method|
            list.response_for(request_with(:method => method))
          end
          list.assert_no_unused_interactions! # should not raise an error.
        end
      end

      describe "has_interaction_matching?" do
        it 'returns false when the list is empty' do
          HTTPInteractionList.new([], [:method]).should_not have_interaction_matching(stub)
        end

        it 'returns false when there is no matching interaction' do
          list.should_not have_interaction_matching(request_with(:method => :get))
        end

        it 'returns true when there is a matching interaction' do
          list.should have_interaction_matching(request_with(:method => :post))
        end

        it 'does not consume the interactions when they match' do
          list.should have_interaction_matching(request_with(:method => :post))
          list.remaining_unused_interaction_count.should eq(3)
          list.should have_interaction_matching(request_with(:method => :post))
          list.remaining_unused_interaction_count.should eq(3)
        end

        it 'invokes each matcher block to find the matching interaction' do
          VCR.request_matchers.register(:foo) { |r1, r2| true }
          VCR.request_matchers.register(:bar) { |r1, r2| true }

          calls = 0
          VCR.request_matchers.register(:baz) { |r1, r2| calls += 1; calls == 2 }

          list = HTTPInteractionList.new([
            interaction('response', :method => :put)
          ], [:foo, :bar, :baz])

          list.should_not have_interaction_matching(request_with(:method => :post))
          list.should     have_interaction_matching(request_with(:method => :post))
        end

        it "delegates to the parent list when it can't find a matching interaction" do
          parent_list = mock(:has_interaction_matching? => true)
          HTTPInteractionList.new( [], [:method], false, parent_list).should have_interaction_matching(stub)
          parent_list = mock(:has_interaction_matching? => false)
          HTTPInteractionList.new( [], [:method], false, parent_list).should_not have_interaction_matching(stub)
        end

        context 'when allow_playback_repeats is set to true' do
          let(:allow_playback_repeats) { true }

          it 'considers used interactions' do
            list.response_for(request_with(:method => :put))

            10.times.map {
              list.has_interaction_matching?(request_with(:method => :put))
            }.should eq([true] * 10)
          end
        end

        context 'when allow_playback_repeats is set to false' do
          let(:allow_playback_repeats) { false }

          it 'does not consider used interactions' do
            list.response_for(request_with(:method => :put))

            10.times.map {
              list.has_interaction_matching?(request_with(:method => :put))
            }.should eq([false] * 10)
          end
        end
      end

      describe "#response_for" do
        it 'returns nil when the list is empty' do
          HTTPInteractionList.new([], [:method]).response_for(stub).should respond_with(nil)
        end

        it 'returns nil when there is no matching interaction' do
          HTTPInteractionList.new([
            interaction('foo', :method => :post),
            interaction('foo', :method => :put)
          ], [:method]).response_for(
            request_with(:method => :get)
          ).should respond_with(nil)
        end

        it 'returns the first matching interaction' do
          list = HTTPInteractionList.new([
            interaction('put response', :method => :put),
            interaction('post response 1', :method => :post),
            interaction('post response 2', :method => :post)
          ], [:method])

          list.response_for(request_with(:method => :post)).should respond_with("post response 1")
        end

        it 'invokes each matcher block to find the matching interaction' do
          VCR.request_matchers.register(:foo) { |r1, r2| true }
          VCR.request_matchers.register(:bar) { |r1, r2| true }

          calls = 0
          VCR.request_matchers.register(:baz) { |r1, r2| calls += 1; calls == 2 }

          list = HTTPInteractionList.new([
            interaction('response', :method => :put)
          ], [:foo, :bar, :baz])

          list.response_for(request_with(:method => :post)).should respond_with(nil)
          list.response_for(request_with(:method => :post)).should respond_with('response')
        end

        it "delegates to the parent list when it can't find a matching interaction" do
          parent_list = mock(:response_for => response('parent'))
          HTTPInteractionList.new(
            [], [:method], false, parent_list
          ).response_for(stub).should respond_with('parent')
        end

        it 'consumes the first matching interaction so that it will not be used again' do
          list.response_for(request_with(:method => :post)).body.should eq("post response 1")
          list.response_for(request_with(:method => :post)).body.should eq("post response 2")
        end

        context 'when allow_playback_repeats is set to true' do
          let(:allow_playback_repeats) { true }

          it 'continues to return the response from the last matching interaction when there are no more' do
            list.response_for(request_with(:method => :post))

            10.times.map {
              response = list.response_for(request_with(:method => :post))
              response ? response.body : nil
            }.should eq(["post response 2"] * 10)
          end
        end

        context 'when allow_playback_repeats is set to false' do
          let(:allow_playback_repeats) { false }

          it 'returns nil when there are no more unused interactions' do
            list.response_for(request_with(:method => :post))
            list.response_for(request_with(:method => :post))

            10.times.map {
              list.response_for(request_with(:method => :post))
            }.should eq([nil] * 10)
          end
        end

        it 'does not modify the original interaction array the list was initialized with' do
          original_dup = original_list_array.dup
          list.response_for(request_with(:method => :post))
          original_list_array.should == original_dup
        end
      end
    end
  end
end

