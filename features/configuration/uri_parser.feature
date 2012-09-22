Feature: uri_parser

  By default, VCR will parse URIs using `URI` from the Ruby standard
  library. The `uri_parser` configuration option will override this
  parser.

  The configured URI parser needs to expose a `.parse` class method
  that returns an instance of the uri. This uri needs to implement the
  folllowing API:

    * `#scheme` => a string
    * `#host`   => a string
    * `#port`   => a fixnum
    * `#path`   => a string
    * `#query`  => a string
    * `#to_s`   => a string
    * `#port=`
    * `#query=`
    * `#==`     => boolean

  Scenario: the VCR uri parser gets its value from `uri_parser`
    Given a file named "uri_parser.rb" with:
      """ruby
      require 'forwardable'
      require 'vcr'

      class DelegatingURI
        extend Forwardable

        def_delegators :@uri, :scheme, :host, :port, :path, :query

        def initialize(uri)
          @uri = uri
        end

        def self.parse(uri_string)
          new(URI.parse(uri_string))
        end
      end

      VCR.configure do |c|
        c.uri_parser = DelegatingURI
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example') do
        puts "URI parser: #{VCR.configuration.uri_parser.to_s}"
      end
      """
     When I run `ruby uri_parser.rb`
     Then the output should contain:
      """
      URI parser: DelegatingURI
      """

  Scenario: the `uri_parser` defaults to the standard library's `URI`
    Given a file named "uri_parser_default.rb" with:
      """ruby
      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('example') do
        puts "URI parser: #{VCR.configuration.uri_parser.to_s}"
      end
      """
     When I run `ruby uri_parser_default.rb`
     Then the output should contain:
     """
     URI parser: URI
     """
