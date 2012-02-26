require 'fileutils'
require 'erb'

require 'vcr/cassette/http_interaction_list'
require 'vcr/cassette/reader'
require 'vcr/cassette/serializers'

module VCR
  # The media VCR uses to store HTTP interactions for later re-use.
  class Cassette
    include Logger

    # The supported record modes.
    #
    #   * :all -- Record every HTTP interactions; do not play any back.
    #   * :none -- Do not record any HTTP interactions; play them back.
    #   * :new_episodes -- Playback previously recorded HTTP interactions and record new ones.
    #   * :once -- Record the HTTP interactions if the cassette has not already been recorded;
    #              otherwise, playback the HTTP interactions.
    VALID_RECORD_MODES = [:all, :none, :new_episodes, :once]

    # @return [#to_s] The name of the cassette. Used to determine the cassette's file name.
    # @see #file
    attr_reader :name

    # @return [Symbol] The record mode. Determines whether the cassette records HTTP interactions,
    #  plays them back, or does both.
    attr_reader :record_mode

    # @return [Array<Symbol, #call>] List of request matchers. Used to find a response from an
    #  existing HTTP interaction to play back.
    attr_reader :match_requests_on

    # @return [Boolean, Hash] The cassette's ERB option. The file will be treated as an
    #  ERB template if this has a truthy value. A hash, if provided, will be used as local
    #  variables for the ERB template.
    attr_reader :erb

    # @return [Integer, nil] How frequently (in seconds) the cassette should be re-recorded.
    attr_reader :re_record_interval

    # @return [Array<Symbol>] If set, {VCR::Configuration#before_record} and
    #  {VCR::Configuration#before_playback} hooks with a corresponding tag will apply.
    attr_reader :tags

    # @param (see VCR#insert_cassette)
    # @see VCR#insert_cassette
    def initialize(name, options = {})
      options = VCR.configuration.default_cassette_options.merge(options)
      invalid_options = options.keys - [
        :record, :erb, :match_requests_on, :re_record_interval, :tag, :tags,
        :update_content_length_header, :allow_playback_repeats, :exclusive,
        :serialize_with, :preserve_exact_body_bytes
      ]

      if invalid_options.size > 0
        raise ArgumentError.new("You passed the following invalid options to VCR::Cassette.new: #{invalid_options.inspect}.")
      end

      @name                         = name
      @record_mode                  = options[:record]
      @erb                          = options[:erb]
      @match_requests_on            = options[:match_requests_on]
      @re_record_interval           = options[:re_record_interval]
      @tags                         = Array(options.fetch(:tags) { options[:tag] })
      @tags                         << :update_content_length_header if options[:update_content_length_header]
      @tags                         << :preserve_exact_body_bytes if options[:preserve_exact_body_bytes]
      @allow_playback_repeats       = options[:allow_playback_repeats]
      @exclusive                    = options[:exclusive]
      @serializer                   = VCR.cassette_serializers[options[:serialize_with]]
      @record_mode                  = :all if should_re_record?
      @parent_list                  = @exclusive ? HTTPInteractionList::NullList : VCR.http_interactions

      raise_error_unless_valid_record_mode

      log "Initialized with options: #{options.inspect}"
    end

    # Ejects the current cassette. The cassette will no longer be used.
    # In addition, any newly recorded HTTP interactions will be written to
    # disk.
    def eject
      write_recorded_interactions_to_disk
    end

    # @private
    def http_interactions
      @http_interactions ||= HTTPInteractionList.new \
        should_stub_requests? ? previously_recorded_interactions : [],
        match_requests_on,
        @allow_playback_repeats,
        @parent_list,
        log_prefix
    end

    # @private
    def record_http_interaction(interaction)
      log "Recorded HTTP interaction #{request_summary(interaction.request)} => #{response_summary(interaction.response)}"
      new_recorded_interactions << interaction
    end

    # @private
    def new_recorded_interactions
      @new_recorded_interactions ||= []
    end

    # @return [String] The file for this cassette.
    # @note VCR will take care of sanitizing the cassette name to make it a valid file name.
    def file
      return nil unless VCR.configuration.cassette_library_dir
      File.join(VCR.configuration.cassette_library_dir, "#{sanitized_name}.#{@serializer.file_extension}")
    end

    # @return [Boolean] Whether or not the cassette is recording.
    def recording?
      case record_mode
        when :none; false
        when :once; file.nil? || !File.size?(file)
        else true
      end
    end

    # @return [Hash] The hash that will be serialized when the cassette is written to disk.
    def serializable_hash
      {
        "http_interactions" => interactions_to_record.map(&:to_hash),
        "recorded_with"     => "VCR #{VCR.version}"
      }
    end

  private

    def previously_recorded_interactions
      @previously_recorded_interactions ||= if file && File.size?(file)
        deserialized_hash['http_interactions'].map { |h| HTTPInteraction.from_hash(h) }.tap do |interactions|
          invoke_hook(:before_playback, interactions)

          interactions.reject! do |i|
            i.request.uri.is_a?(String) && VCR.request_ignorer.ignore?(i.request)
          end
        end
      else
        []
      end
    end

    def sanitized_name
      name.to_s.gsub(/[^\w\-\/]+/, '_')
    end

    def raise_error_unless_valid_record_mode
      unless VALID_RECORD_MODES.include?(record_mode)
        raise ArgumentError.new("#{record_mode} is not a valid cassette record mode.  Valid modes are: #{VALID_RECORD_MODES.inspect}")
      end
    end

    def should_re_record?
      return false unless @re_record_interval
      previously_recorded_at = earliest_interaction_recorded_at
      return false unless previously_recorded_at
      return false unless File.exist?(file)

      now = Time.now

      (previously_recorded_at + @re_record_interval < now).tap do |value|
        info = "previously recorded at: '#{previously_recorded_at}'; now: '#{now}'; interval: #{@re_record_interval} seconds"

        if !value
          log "Not re-recording since the interval has not elapsed (#{info})."
        elsif InternetConnection.available?
          log "re-recording (#{info})."
        else
          log "Not re-recording because no internet connection is available (#{info})."
          return false
        end
      end
    end

    def earliest_interaction_recorded_at
      previously_recorded_interactions.map(&:recorded_at).min
    end

    def should_stub_requests?
      record_mode != :all
    end

    def should_remove_matching_existing_interactions?
      record_mode == :all
    end

    def raw_yaml_content
      VCR::Cassette::Reader.new(file, erb).read
    end

    def merged_interactions
      old_interactions = previously_recorded_interactions

      if should_remove_matching_existing_interactions?
        new_interaction_list = HTTPInteractionList.new(new_recorded_interactions, match_requests_on)
        old_interactions = old_interactions.reject do |i|
          new_interaction_list.response_for(i.request)
        end
      end

      old_interactions + new_recorded_interactions
    end

    def interactions_to_record
      merged_interactions.tap do |interactions|
        invoke_hook(:before_record, interactions)
      end
    end

    def write_recorded_interactions_to_disk
      return unless VCR.configuration.cassette_library_dir
      return if new_recorded_interactions.none?
      hash = serializable_hash
      return if hash["http_interactions"].none?

      directory = File.dirname(file)
      FileUtils.mkdir_p directory unless File.exist?(directory)
      File.open(file, 'w') { |f| f.write @serializer.serialize(hash) }
    end

    def invoke_hook(type, interactions)
      interactions.delete_if do |i|
        i.hook_aware.tap do |hw|
          VCR.configuration.invoke_hook(type, hw, self)
        end.ignored?
      end
    end

    def deserialized_hash
      @deserialized_hash ||= @serializer.deserialize(raw_yaml_content).tap do |hash|
        unless hash.is_a?(Hash) && hash['http_interactions'].is_a?(Array)
          raise Errors::InvalidCassetteFormatError.new \
            "#{file} does not appear to be a valid VCR 2.0 cassette. " +
            "VCR 1.x cassettes are not valid with VCR 2.0. When upgrading from " +
            "VCR 1.x, it is recommended that you delete all your existing cassettes and " +
            "re-record them, or use the provided vcr:migrate_cassettes rake task to migrate " +
            "them. For more info, see the VCR upgrade guide."
        end
      end
    end

    def log_prefix
      @log_prefix ||= "[Cassette: '#{name}'] "
    end

    def request_summary(request)
      super(request, match_requests_on)
    end
  end
end
