module VCR
  # Namespace for VCR errors.
  module Errors
    # Base class for all VCR errors.
    class Error                     < StandardError; end

    # Error raised when VCR is turned off while a cassette is in use.
    # @see VCR#turn_off!
    # @see VCR#turned_off
    class CassetteInUseError        < Error; end

    # Error raised when a VCR cassette is inserted while VCR is turned off.
    # @see VCR#insert_cassette
    # @see VCR#use_cassette
    class TurnedOffError            < Error; end

    # Error raised when an cassette ERB template is rendered and a
    # variable is missing.
    # @see VCR#insert_cassette
    # @see VCR#use_cassette
    class MissingERBVariableError   < Error; end

    # Error raised when the version of one of the libraries that VCR hooks into
    # is too low for VCR to support.
    # @see VCR::Configuration#hook_into
    class LibraryVersionTooLowError < Error; end

    # Error raised when a request matcher is requested that is not registered.
    class UnregisteredMatcherError  < Error; end

    # Error raised when a VCR 1.x cassette is used with VCR 2.
    class InvalidCassetteFormatError < Error; end

    # Error raised when an +around_http_request+ hook is used improperly.
    # @see VCR::Configuration#around_http_request
    class AroundHTTPRequestHookError < Error; end

    # Error raised when you attempt to use a VCR feature that is not
    # supported on your ruby interpreter.
    # @see VCR::Configuration#around_http_request
    class NotSupportedError          < Error; end

    # Error raised when you ask VCR to decode a compressed response
    # body but the content encoding isn't one of the known ones.
    # @see VCR::Response#decompress
    class UnknownContentEncodingError < Error; end

    # Error raised when you eject a cassette when not all HTTP
    # interactions were already played back.
    # @note Only applicable when :allow_episode_skipping is false.
    # @see VCR::HTTPInteractionList#assert_finished!
    class SkippedHTTPRequestError < Error; end

    # Error raised when an HTTP request is made that VCR is unable to handle.
    # @note VCR will raise this to force you to do something about the
    #  HTTP request. The idea is that you want to handle _every_ HTTP
    #  request in your test suite. The error message will give you
    #  suggestions for how to deal with the request.
    class UnhandledHTTPRequestError < Error
      # The HTTP request.
      attr_reader :request

      # Constructs the error.
      #
      # @param [VCR::Request] request the unhandled request.
      def initialize(request)
        @request = request
        super construct_message
      end

    private

      def relish_version_slug
        @relish_version_slug ||= VCR.version.gsub(/\W/, '-')
      end

      def construct_message
        ["", "", "=" * 80,
         "An HTTP request has been made that VCR does not know how to handle:",
         "  #{request_description}\n",
         cassette_description,
         formatted_suggestions,
         "=" * 80, "", ""].join("\n")
      end

      def request_description
        "#{request.method.to_s.upcase} #{request.uri}"
      end

      def cassette_description
        if cassette = VCR.current_cassette
          ["VCR is currently using the following cassette:",
           "  - #{cassette.file}",
           "  - :record => #{cassette.record_mode.inspect}",
           "  - :match_requests_on => #{cassette.match_requests_on.inspect}\n",
           "Under the current configuration VCR can not find a suitable HTTP interaction",
           "to replay and is prevented from recording new requests. There are a few ways",
           "you can deal with this:\n"].join("\n")
        else
          ["There is currently no cassette in use. There are a few ways",
           "you can configure VCR to handle this request:\n"].join("\n")
        end
      end

      def formatted_suggestions
        formatted_points, formatted_foot_notes = [], []

        suggestions.each_with_index do |suggestion, index|
          bullet_point, foot_note = suggestion.first, suggestion.last
          formatted_points << format_bullet_point(bullet_point, index)
          formatted_foot_notes << format_foot_note(foot_note, index)
        end

        [
          formatted_points.join("\n"),
          formatted_foot_notes.join("\n")
        ].join("\n\n")
      end

      def format_bullet_point(lines, index)
        lines.first.insert(0, "  * ")
        lines.last << " [#{index + 1}]."
        lines.join("\n    ")
      end

      def format_foot_note(url, index)
        "[#{index + 1}] #{url % relish_version_slug}"
      end

      # List of suggestions for how to configure VCR to handle the request.
      ALL_SUGGESTIONS = {
        :use_new_episodes => [
          ["You can use the :new_episodes record mode to allow VCR to",
           "record this new request to the existing cassette"],
          "https://www.relishapp.com/myronmarston/vcr/v/%s/docs/record-modes/new-episodes"
        ],

        :delete_cassette_for_once => [
          ["The current record mode (:once) does not allow new requests to be recorded",
           "to a previously recorded cassette. You can delete the cassette file and re-run",
           "your tests to allow the cassette to be recorded with this request"],
           "https://www.relishapp.com/myronmarston/vcr/v/%s/docs/record-modes/once"
        ],

        :deal_with_none => [
          ["The current record mode (:none) does not allow requests to be recorded. You",
           "can temporarily change the record mode to :once, delete the cassette file ",
           "and re-run your tests to allow the cassette to be recorded with this request"],
           "https://www.relishapp.com/myronmarston/vcr/v/%s/docs/record-modes/none"
        ],

        :use_a_cassette => [
          ["If you want VCR to record this request and play it back during future test",
           "runs, you should wrap your test (or this portion of your test) in a",
           "`VCR.use_cassette` block"],
          "https://www.relishapp.com/myronmarston/vcr/v/%s/docs/getting-started"
        ],

        :allow_http_connections_when_no_cassette => [
          ["If you only want VCR to handle requests made while a cassette is in use,",
           "configure `allow_http_connections_when_no_cassette = true`. VCR will",
           "ignore this request since it is made when there is no cassette"],
          "https://www.relishapp.com/myronmarston/vcr/v/%s/docs/configuration/allow-http-connections-when-no-cassette"
        ],

        :ignore_request => [
          ["If you want VCR to ignore this request (and others like it), you can",
           "set an `ignore_request` callback"],
          "https://www.relishapp.com/myronmarston/vcr/v/%s/docs/configuration/ignore-request"
        ],

        :allow_playback_repeats => [
          ["The cassette contains an HTTP interaction that matches this request,",
           "but it has already been played back. If you wish to allow a single HTTP",
           "interaction to be played back multiple times, set the `:allow_playback_repeats`",
           "cassette option"],
          "https://www.relishapp.com/myronmarston/vcr/v/%s/docs/request-matching/playback-repeats"
        ],

        :match_requests_on => [
          ["The cassette contains %s not been",
           "played back. If your request is non-deterministic, you may need to",
           "change your :match_requests_on cassette option to be more lenient",
           "or use a custom request matcher to allow it to match"],
           "https://www.relishapp.com/myronmarston/vcr/v/%s/docs/request-matching"
        ]
      }

      def suggestion_for(key)
        bullet_point_lines, url = ALL_SUGGESTIONS[key]
        bullet_point_lines = bullet_point_lines.map(&:dup)
        url = url.dup
        [bullet_point_lines, url]
      end

      def suggestions
        return no_cassette_suggestions unless cassette = VCR.current_cassette

        [:use_new_episodes, :ignore_request].tap do |suggestions|
          suggestions.push(*record_mode_suggestion)
          suggestions << :allow_playback_repeats if cassette.http_interactions.has_used_interaction_matching?(request)
          suggestions.map! { |k| suggestion_for(k) }
          suggestions.push(*match_requests_on_suggestion)
        end
      end

      def no_cassette_suggestions
        [:use_a_cassette, :allow_http_connections_when_no_cassette, :ignore_request].map do |key|
          suggestion_for(key)
        end
      end

      def record_mode_suggestion
        case VCR.current_cassette.record_mode
        when :none then [:deal_with_none]
        when :once then [:delete_cassette_for_once]
        else []
        end
      end

      def match_requests_on_suggestion
        num_remaining_interactions = VCR.current_cassette.http_interactions.remaining_unused_interaction_count
        return [] if num_remaining_interactions.zero?

        interaction_description = if num_remaining_interactions == 1
          "1 HTTP interaction that has"
        else
          "#{num_remaining_interactions} HTTP interactions that have"
        end

        description_lines, link = suggestion_for(:match_requests_on)
        description_lines[0] = description_lines[0] % interaction_description
        [[description_lines, link]]
      end

    end
  end
end

