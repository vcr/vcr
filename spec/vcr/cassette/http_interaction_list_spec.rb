require 'vcr/cassette/http_interaction_list'
require 'vcr/request_matcher_registry'
require 'vcr/structs'
require 'uri'

module VCR
  class Cassette

    shared_examples_for "an HTTP interaction finding method" do |method|
      it 'returns nil when the list is empty' do
        HTTPInteractionList.new([], [:method]).send(method, stub).should respond_with(nil)
      end

      it 'returns nil when there is no matching interaction' do
        HTTPInteractionList.new([
          interaction('foo', :method => :post),
          interaction('foo', :method => :put)
        ], [:method]).send(method,
          request_with(:method => :get)
        ).should respond_with(nil)
      end

      it 'returns the first matching interaction' do
        list = HTTPInteractionList.new([
          interaction('put response', :method => :put),
          interaction('post response 1', :method => :post),
          interaction('post response 2', :method => :post)
        ], [:method])

        list.send(method, request_with(:method => :post)).should respond_with("post response 1")
      end

      it 'invokes each matcher block to find the matching interaction' do
        VCR.request_matchers.register(:foo) { |r1, r2| true }
        VCR.request_matchers.register(:bar) { |r1, r2| true }

        calls = 0
        VCR.request_matchers.register(:baz) { |r1, r2| calls += 1; calls == 2 }

        list = HTTPInteractionList.new([
          interaction('response', :method => :put)
        ], [:foo, :bar, :baz])

        list.send(method, request_with(:method => :post)).should respond_with(nil)
        list.send(method, request_with(:method => :post)).should respond_with('response')
      end

      it "delegates to the parent list when it can't find a matching interaction" do
        parent_list = mock(method => response('parent'))
        HTTPInteractionList.new(
          [], [:method], false, parent_list
        ).send(method, stub).should respond_with('parent')
      end
    end

    describe HTTPInteractionList do
      before(:each) do
        VCR.stub(:request_matchers => VCR::RequestMatcherRegistry.new)
      end

      def request_with(values)
        VCR::Request.new.tap do |request|
          values.each do |name, value|
            request.send("#{name}=", value)
          end
        end
      end

      def response(body)
        VCR::Response.new.tap { |r| r.body = body }
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

      describe "#response_for" do
        it_behaves_like "an HTTP interaction finding method", :response_for do
          def respond_with(value)
            ::RSpec::Matchers::Matcher.new :respond_with, value do |expected|
              match { |a| expected.nil? ? a.nil? : a.body == expected }
            end
          end
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

