module VCR
  class Cassette
    class HTTPInteractionList
      module NullList
        extend self
        def response_for(*a); nil; end
        def has_interaction_matching?(*a); false; end
        def has_used_interaction_matching?(*a); false; end
        def remaining_unused_interaction_count(*a); 0; end
      end

      attr_reader :interactions, :request_matchers, :allow_playback_repeats, :parent_list

      def initialize(interactions, request_matchers, allow_playback_repeats = false, parent_list = NullList)
        @interactions           = interactions.dup
        @request_matchers       = request_matchers.map { |m| VCR.request_matchers[m] }
        @allow_playback_repeats = allow_playback_repeats
        @parent_list            = parent_list
        @used_interactions      = []
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

      def has_used_interaction_matching?(request)
        @used_interactions.any? { |i| interaction_matches_request?(request, i) }
      end

      def remaining_unused_interaction_count
        @interactions.size
      end

    private

      def matching_interaction_index_for(request)
        @interactions.index { |i| interaction_matches_request?(request, i) }
      end

      def matching_used_interaction_for(request)
        return nil unless @allow_playback_repeats
        @used_interactions.find { |i| interaction_matches_request?(request, i) }
      end

      def interaction_matches_request?(request, interaction)
        @request_matchers.all? do |matcher|
          matcher.matches?(request, interaction.request)
        end
      end
    end
  end
end

