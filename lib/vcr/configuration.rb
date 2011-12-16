require 'fileutils'
require 'vcr/util/hooks'

module VCR
  # Stores the VCR configuration.
  class Configuration
    include VCR::Hooks
    include VCR::VariableArgsBlockCaller

    # Adds a callback that will be called before the recorded HTTP interactions
    # are serialized and written to disk.
    #
    # @example
    #  VCR.configure do |c|
    #    # Don't record transient 5xx errors
    #    c.before_record do |interaction|
    #      interaction.ignore! if interaction.response.status.code >= 500
    #    end
    #
    #    # Modify the response body for cassettes tagged with :twilio
    #    c.before_record(:twilio) do |interaction|
    #      interaction.response.body.downcase!
    #    end
    #  end
    #
    # @param tag [(optional) Symbol] Used to apply this hook to only cassettes that match
    #  the given tag.
    # @yield the callback
    # @yieldparam interaction [VCR::HTTPInteraction] The interaction that will be
    #  serialized and written to disk.
    # @yieldparam cassette [(optional) VCR::Cassette] The current cassette.
    # @see #before_playback
    define_hook :before_record

    # Adds a callback that will be called before a previously recorded
    # HTTP interaction is loaded for playback.
    #
    # @example
    #  VCR.configure do |c|
    #    # Don't playback transient 5xx errors
    #    c.before_playback do |interaction|
    #      interaction.ignore! if interaction.response.status.code >= 500
    #    end
    #
    #    # Change a response header for playback
    #    c.before_playback(:twilio) do |interaction|
    #      interaction.response.headers['X-Foo-Bar'] = 'Bazz'
    #    end
    #  end
    #
    # @param tag [(optional) Symbol] Used to apply this hook to only cassettes that match
    #  the given tag.
    # @yield the callback
    # @yieldparam interaction [VCR::HTTPInteraction] The interaction that is being
    #  loaded.
    # @yieldparam cassette [(optional) VCR::Cassette] The current cassette.
    # @see #before_record
    define_hook :before_playback

    # @private
    define_hook :after_library_hooks_loaded

    # Adds a callback that will be called with each HTTP request before it is made.
    #
    # @example
    #  VCR.configure do |c|
    #    c.before_http_request do |request|
    #      puts "Request: #{request.method} #{request.uri}"
    #    end
    #  end
    #
    # @yield the callback
    # @yieldparam request [VCR::Request] the request that is being made
    # @see #after_http_request
    # @see #around_http_request
    define_hook :before_http_request

    # Adds a callback that will be called with each HTTP request after it is complete.
    #
    # @example
    #  VCR.configure do |c|
    #    c.after_http_request do |request, response|
    #      puts "Request: #{request.method} #{request.uri}"
    #      puts "Response: #{response.status.code}"
    #    end
    #  end
    #
    # @yield the callback
    # @yieldparam request [VCR::Request] the request that is being made
    # @yieldparam response [VCR::Response] the response from the request
    # @see #before_http_request
    # @see #around_http_request
    define_hook :after_http_request, :prepend

    # @private
    def initialize
      @allow_http_connections_when_no_cassette = nil
      @default_cassette_options = {
        :record            => :once,
        :match_requests_on => RequestMatcherRegistry::DEFAULT_MATCHERS,
        :serialize_with    => :yaml
      }
    end

    # The directory to write cassettes to and read them from.
    attr_reader :cassette_library_dir

    # Sets the directory to write cassettes to and read them from.
    def cassette_library_dir=(cassette_library_dir)
      @cassette_library_dir = cassette_library_dir
      FileUtils.mkdir_p(cassette_library_dir) if cassette_library_dir
    end

    attr_reader :default_cassette_options
    def default_cassette_options=(overrides)
      @default_cassette_options.merge!(overrides)
    end

    # Configures which libraries VCR will hook into to intercept HTTP requests.
    #
    # @example
    #   VCR.configure do |c|
    #     c.hook_into :fakeweb, :typhoeus
    #   end
    #
    # @param hooks [Array<Symbol>] List of libraries. Valid values are
    #  +:fakeweb+, +:webmock+, +:typhoeus+, +:excon+ and +:faraday+.
    # @raise [ArgumentError] when given an unsupported library name.
    # @raise [VCR::Errors::LibraryVersionTooLowError] when the version
    #  of a library you are using is too low for VCR to support.
    # @note +:fakeweb+ and +:webmock+ cannot both be used since they both monkey patch
    #  +Net::HTTP+. Otherwise, you can use any combination of these.
    def hook_into(*hooks)
      hooks.each { |a| load_library_hook(a) }
      invoke_hook(:after_library_hooks_loaded)
    end

    # Registers a request matcher for later use.
    #
    # @example
    #  VCR.configure do |c|
    #    c.register_request_matcher :port do |request_1, request_2|
    #      URI(request_1.uri).port == URI(request_2.uri).port
    #    end
    #  end
    #
    #  VCR.use_cassette("my_cassette", :match_requests_on => [:method, :host, :port]) do
    #    # ...
    #  end
    #
    # @param name [Symbol] the name of the request matcher
    # @yield the request matcher
    # @yieldparam request_1 [VCR::Request] One request
    # @yieldparam request_2 [VCR::Request] The other request
    # @yieldreturn [Boolean] whether or not these two requests should be considered
    #  equivalent
    def register_request_matcher(name, &block)
      VCR.request_matchers.register(name, &block)
    end

    # Specifies host(s) that VCR should ignore.
    #
    # @param hosts [Array<String>] List of hosts to ignore
    # @see #ignore_localhost=
    # @see #ignore_request
    def ignore_hosts(*hosts)
      VCR.request_ignorer.ignore_hosts(*hosts)
    end
    alias ignore_host ignore_hosts

    # Sets whether or not VCR should ignore localhost requests.
    #
    # @param value [Boolean] the value to set
    # @see #ignore_hosts
    # @see #ignore_request
    def ignore_localhost=(value)
      VCR.request_ignorer.ignore_localhost = value
    end

    # Defines what requests to ignore using a block.
    #
    # @example
    #   VCR.configure do |c|
    #     c.ignore_request do |request|
    #       uri = URI(request.uri)
    #       # ignore only localhost requests to port 7500
    #       uri.host == 'localhost' && uri.port == 7500
    #     end
    #   end
    #
    # @yield the callback
    # @yieldparam request [VCR::Request] the HTTP request
    # @yieldreturn [Boolean] whether or not to ignore the request
    def ignore_request(&block)
      VCR.request_ignorer.ignore_request(&block)
    end

    attr_writer :allow_http_connections_when_no_cassette
    def allow_http_connections_when_no_cassette?
      !!@allow_http_connections_when_no_cassette
    end

    def filter_sensitive_data(placeholder, tag = nil, &block)
      before_record(tag) do |interaction|
        interaction.filter!(call_block(block, interaction), placeholder)
      end

      before_playback(tag) do |interaction|
        interaction.filter!(placeholder, call_block(block, interaction))
      end
    end
    alias define_cassette_placeholder filter_sensitive_data

    # Gets the registry of cassette serializers. Use it to register a custom serializer.
    #
    # @example
    #   VCR.configure do |c|
    #     c.cassette_serializers[:my_custom_serializer] = my_custom_serializer
    #   end
    #
    # @return [VCR::Cassette::Serializers] the cassette serializer registry object.
    # @note Custom serializers must implement the following interface:
    #   * +file_extension      # => String+
    #   * +serialize(Hash)     # => String+
    #   * +deserialize(String) # => Hash+
    def cassette_serializers
      VCR.cassette_serializers
    end

    # Adds a callback that will be executed around each HTTP request.
    #
    # @example
    #  VCR.configure do |c|
    #    c.around_http_request do |request|
    #      uri = URI(request.uri)
    #      if uri.host == 'api.geocoder.com'
    #        # extract an address like "1700 E Pine St, Seattle, WA"
    #        # from a query like "address=1700+E+Pine+St%2C+Seattle%2C+WA"
    #        address = CGI.unescape(uri.query.split('=').last)
    #        VCR.use_cassette("geocoding/#{address}", &request)
    #      else
    #        request.proceed
    #      end
    #    end
    #  end
    #
    # @yield the callback
    # @yieldparam request [VCR::Request] the request that is being made
    # @raise [VCR::Errors::NotSupportedError] if the fiber library cannot be loaded.
    # @note This method can only be used on ruby interpreters that support
    #  fibers (i.e. 1.9+). On 1.8 you can use separate +before_http_request+ and
    #  +after_http_request+ hooks.
    # @note You _must_ call +request.proceed+ or pass the request as a proc on to a
    #  method that expects a block (i.e. some_method(&request)).
    # @see #before_http_request
    # @see #after_http_request
    def around_http_request(&block)
      require 'fiber'
    rescue LoadError
      raise Errors::NotSupportedError.new \
        "VCR::Configuration#around_http_request requires fibers, " +
        "which are not available on your ruby intepreter."
    else
      fiber, hook_decaration = nil, caller.first
      before_http_request { |request| fiber = start_new_fiber_for(request, block) }
      after_http_request  { |request, response| resume_fiber(fiber, response, hook_decaration) }
    end

    # Configures RSpec to use a VCR cassette for any example
    # tagged with +:vcr+.
    def configure_rspec_metadata!
      VCR::RSpec::Metadata.configure!
    end

  private

    def load_library_hook(hook)
      file = "vcr/library_hooks/#{hook}"
      require file
    rescue LoadError => e
      raise e unless e.message.include?(file) # in case FakeWeb/WebMock/etc itself is not available
      raise ArgumentError.new("#{hook.inspect} is not a supported VCR HTTP library hook.")
    end

    def resume_fiber(fiber, response, hook_declaration)
      fiber.resume(response)
    rescue FiberError
      raise Errors::AroundHTTPRequestHookError.new \
        "Your around_http_request hook declared at #{hook_declaration}" +
        " must call #proceed on the yielded request but did not."
    end

    def start_new_fiber_for(request, block)
      Fiber.new(&block).tap do |fiber|
        fiber.resume(request.fiber_aware)
      end
    end
  end
end

