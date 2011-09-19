require 'vcr/util/version_checker'

module VCR
  module HttpStubbingAdapters
    autoload :Excon,            'vcr/http_stubbing_adapters/excon'
    autoload :FakeWeb,          'vcr/http_stubbing_adapters/fakeweb'
    autoload :Faraday,          'vcr/http_stubbing_adapters/faraday'
    autoload :MultiObjectProxy, 'vcr/http_stubbing_adapters/multi_object_proxy'
    autoload :Typhoeus,         'vcr/http_stubbing_adapters/typhoeus'
    autoload :WebMock,          'vcr/http_stubbing_adapters/webmock'

    class UnsupportedRequestMatchAttributeError < ArgumentError; end
    class HttpConnectionNotAllowedError < StandardError; end

    module Common
      class << self
        attr_accessor :exclusively_enabled_adapter

        def add_vcr_info_to_exception_message(exception_klass)
          exception_klass.class_eval do
            def initialize(message)
              super(message + '.  ' + VCR::HttpStubbingAdapters::Common::RECORDING_INSTRUCTIONS)
            end
          end
        end

        def adapters
          @adapters ||= []
        end

        def included(adapter)
          adapters << adapter
        end
      end

      RECORDING_INSTRUCTIONS = "You can use VCR to automatically record this request and replay it later.  " +
                               "For more details, visit the VCR documentation at: http://relishapp.com/myronmarston/vcr/v/#{VCR.version.gsub('.', '-')}"

      def enabled?
        [nil, self].include? VCR::HttpStubbingAdapters::Common.exclusively_enabled_adapter
      end

      def after_adapters_loaded
        # no-op
      end

      def exclusively_enabled
        VCR::HttpStubbingAdapters::Common.exclusively_enabled_adapter = self

        begin
          yield
        ensure
          VCR::HttpStubbingAdapters::Common.exclusively_enabled_adapter = nil
        end
      end

      def check_version!
        VersionChecker.new(
          library_name,
          version,
          self::MIN_PATCH_LEVEL,
          self::MAX_MINOR_VERSION
        ).check_version!
      end

      def library_name
        @library_name ||= self.to_s.split('::').last
      end

      def set_http_connections_allowed_to_default
        self.http_connections_allowed = VCR.configuration.allow_http_connections_when_no_cassette?
      end

      def raise_no_checkpoint_error(cassette)
        raise ArgumentError.new("No checkpoint for #{cassette.inspect} could be found")
      end

      attr_writer :http_connections_allowed

      def http_connections_allowed?
        defined?(@http_connections_allowed) && !!@http_connections_allowed
      end

      def ignored_hosts=(hosts)
        @ignored_hosts = hosts
      end

      def uri_should_be_ignored?(uri)
        uri = URI.parse(uri) unless uri.respond_to?(:host)
        ignored_hosts.include?(uri.host)
      end

      def stub_requests(http_interactions, match_attributes)
        match_attributes_stack << match_attributes
        grouped_responses(http_interactions, match_attributes).each do |request_matcher, responses|
          request_matcher = request_matcher_with_normalized_uri(request_matcher)
          queue = stub_queues[request_matcher]
          responses.each { |res| queue << res }
        end
      end

      def create_stubs_checkpoint(cassette)
        checkpoints[cassette] = stub_queue_dup
      end

      def restore_stubs_checkpoint(cassette)
        match_attributes_stack.pop
        @stub_queues = checkpoints.delete(cassette) || raise_no_checkpoint_error(cassette)
      end

      def stubbed_response_for(request, remove = true)
        return nil unless match_attributes_stack.any?
        request_matcher = request.matcher(match_attributes_stack.last)
        queue = stub_queues[request_matcher]

        if remove && queue.size > 1
          queue.shift
        else
          queue.first
        end
      end

      def has_stubbed_response_for?(request)
        !!stubbed_response_for(request, false)
      end

      def reset!
        instance_variables.each do |ivar|
          remove_instance_variable(ivar)
        end
      end

      def raise_connections_disabled_error(request)
        raise HttpConnectionNotAllowedError.new(
          "Real HTTP connections are disabled. Request: #{request.method.to_s.upcase} #{request.uri}.  " +
          RECORDING_INSTRUCTIONS
        )
      end

    private

      def ignored_hosts
        @ignored_hosts ||= []
      end

      def checkpoints
        @checkpoints ||= {}
      end

      def stub_queues
        @stub_queues ||= hash_of_arrays
      end

      def match_attributes_stack
        @match_attributes_stack ||= []
      end

      def stub_queue_dup
        dup = hash_of_arrays

        stub_queues.each do |k, v|
          dup[k] = v.dup
        end

        dup
      end

      def hash_of_arrays
        Hash.new { |h, k| h[k] = [] }
      end

      def grouped_responses(http_interactions, match_attributes)
        responses = Hash.new { |h,k| h[k] = [] }

        http_interactions.each do |i|
          responses[i.request.matcher(match_attributes)] << i.response
        end

        responses
      end

      def normalize_uri(uri)
        uri # adapters can override this
      end

      def request_matcher_with_normalized_uri(matcher)
        normalized_uri = normalize_uri(matcher.request.uri)
        return matcher unless matcher.request.uri != normalized_uri

        request = matcher.request.dup
        request.uri = normalized_uri

        RequestMatcher.new(request, matcher.match_attributes)
      end
    end
  end
end
