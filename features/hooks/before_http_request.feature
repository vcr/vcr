Feature: before_http_request hook

  The `before_http_request` hook gets called with each request
  just before it proceeds. It can be used for many things:

    * globally logging requests
    * inserting a particular cassette based on the request URI host
    * raising a timeout error

  You can also pass one or more "filters" to `before_http_request`, to make
  the hook only be called for some requests. Any object that responds to `#to_proc`
  can be a filter.  Here are some simple examples:

    * `:real?` -- only real requests
    * `:stubbed?` -- only stubbed requests
    * `:ignored?` -- only ignored requests
    * `:recordable?` -- only requests that are being recorded
    * `lambda { |r| URI(r.uri).host == 'amazon.com' }` -- only requests to amazon.com.

  Scenario Outline: log all requests using a before_http_request hook
    Given a file named "before_http_request.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      if ARGV.include?('--with-server')
        $server = start_sinatra_app do
          get('/') { "Hello World" }
        end
      end

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
        c.before_http_request(:real?) do |request|
          File.open(ARGV.first, 'w') do |f|
            f.write("before real request: #{request.method} #{request.uri}")
          end
        end
      end

      VCR.use_cassette('hook_example') do
        port = $server ? $server.port : 0
        make_http_request(:get, "http://localhost:#{port}/")
      end
      """
    When I run `ruby before_http_request.rb run1.log --with-server`
    Given that port numbers in "run1.log" are normalized to "7777"
    Then the file "run1.log" should contain "before real request: get http://localhost:7777/"
    When I run `ruby before_http_request.rb run2.log`
    Then the file "run2.log" should not exist

   Examples:
      | configuration         | http_lib              |
      | c.hook_into :fakeweb  | net/http              |
      | c.hook_into :webmock  | net/http              |
      | c.hook_into :webmock  | httpclient            |
      | c.hook_into :webmock  | curb                  |
      | c.hook_into :typhoeus | typhoeus              |
      | c.hook_into :excon    | excon                 |
      | c.hook_into :faraday  | faraday (w/ net_http) |

