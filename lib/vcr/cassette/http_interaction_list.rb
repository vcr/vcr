module VCR
  class Cassette
    class HTTPInteractionList
      class NullList
        def response_for(*a); nil; end
        def has_interaction_matching?(*a); false; end
      end

      attr_reader :interactions, :request_matchers

      def initialize(interactions, request_matchers, parent_list = NullList.new)
        @interactions      = interactions.dup
        @request_matchers  = request_matchers
        @parent_list       = parent_list
        @used_interactions = []
      end

      def response_for(request)
        if index = matching_interaction_index_for(request)
          interaction = @interactions.delete_at(index)
          @used_interactions.unshift interaction
          interaction.response
        elsif interaction = matching_used_interaction_for(request)
          interaction.response
        else
          @parent_list.response_for(request)
        end
      end

      def has_interaction_matching?(request)
        !!matching_interaction_index_for(request) ||
        !!matching_used_interaction_for(request) ||
        @parent_list.has_interaction_matching?(request)
      end

    private

      def matching_interaction_index_for(request)
        @interactions.index { |i| interaction_matches_request?(request, i) }
      end

      def matching_used_interaction_for(request)
        @used_interactions.find { |i| interaction_matches_request?(request, i) }
      end

      def interaction_matches_request?(request, interaction)
        @request_matchers.all? do |matcher|
          VCR.request_matcher_registry[matcher].matches?(request, interaction.request)
        end
      end
    end
  end
end

