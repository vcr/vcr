@exclude-jruby @exclude-rbx
Feature: EM HTTP Request

  EM HTTP Request allows multiple simultaneous asynchronous requests.
  (The other HTTP libraries are synchronous).  The scenarios below
  demonstrate how VCR can be used with asynchronous em-http requests.

  Background:
    Given a file named "vcr_setup.rb" with:
      """ruby
      require 'em-http-request'

      $server = start_sinatra_app do
        %w[ foo bar bazz ].each_with_index do |path, index|
          get "/#{path}" do
            sleep index * 0.1 # ensure the async callbacks are invoked in order
            ARGV[0] + ' ' + path
          end
        end
      end

      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
        c.before_record do |i|
          i.request.uri.sub!(/:\d+/, ':7777')
        end
      end
      """

  Scenario: multiple simultaneous HttpRequest objects
    Given a file named "make_requests.rb" with:
      """ruby
      require 'vcr_setup'

      VCR.use_cassette('em_http') do
        EventMachine.run do
          http_array = %w[ foo bar bazz ].map do |p|
            EventMachine::HttpRequest.new("http://localhost:#{$server.port}/#{p}").get
          end

          http_array.each do |http|
            http.callback do
              puts http.response

              if http_array.all? { |h| h.response.to_s != '' }
                EventMachine.stop
              end
            end
          end
        end
      end
      """
    When I run `ruby make_requests.rb Hello`
    Then the output should contain:
      """
      Hello foo
      Hello bar
      Hello bazz
      """
    And the file "cassettes/em_http.yml" should contain YAML like:
      """
      --- 
      http_interactions: 
      - request: 
          method: get
          uri: http://localhost:7777/foo
          body: 
            encoding: UTF-8
            string: ""
          headers: {}
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Type: 
            - text/html;charset=utf-8
            Content-Length: 
            - "9"
          body: 
            encoding: UTF-8
            string: Hello foo
          http_version: 
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request: 
          method: get
          uri: http://localhost:7777/bar
          body: 
            encoding: UTF-8
            string: ""
          headers: {}
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Type: 
            - text/html;charset=utf-8
            Content-Length: 
            - "9"
          body: 
            encoding: UTF-8
            string: Hello bar
          http_version: 
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request: 
          method: get
          uri: http://localhost:7777/bazz
          body: 
            encoding: UTF-8
            string: ""
          headers: {}
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Type: 
            - text/html;charset=utf-8
            Content-Length: 
            - "10"
          body: 
            encoding: UTF-8
            string: Hello bazz
          http_version: 
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

    When I run `ruby make_requests.rb Goodbye`
    Then the output should contain:
      """
      Hello foo
      Hello bar
      Hello bazz
      """

  Scenario: MultiRequest
    Given a file named "make_requests.rb" with:
      """ruby
      require 'vcr_setup'

      VCR.use_cassette('em_http') do
        EventMachine.run do
          multi = EventMachine::MultiRequest.new

          %w[ foo bar bazz ].each do |path|
            multi.add(path, EventMachine::HttpRequest.new("http://localhost:#{$server.port}/#{path}").get)
          end

          multi.callback do
            responses = Hash[multi.responses[:callback]]

            %w[ foo bar bazz ].each do |path|
              puts responses[path].response
            end

            EventMachine.stop
          end
        end
      end
      """
    When I run `ruby make_requests.rb Hello`
    Then the output should contain:
      """
      Hello foo
      Hello bar
      Hello bazz
      """
    And the file "cassettes/em_http.yml" should contain YAML like:
      """
      --- 
      http_interactions: 
      - request: 
          method: get
          uri: http://localhost:7777/foo
          body: 
            encoding: UTF-8
            string: ""
          headers: {}
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Type: 
            - text/html;charset=utf-8
            Content-Length: 
            - "9"
          body: 
            encoding: UTF-8
            string: Hello foo
          http_version: 
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request: 
          method: get
          uri: http://localhost:7777/bar
          body: 
            encoding: UTF-8
            string: ""
          headers: {}
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Type: 
            - text/html;charset=utf-8
            Content-Length: 
            - "9"
          body: 
            encoding: UTF-8
            string: Hello bar
          http_version: 
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      - request: 
          method: get
          uri: http://localhost:7777/bazz
          body: 
            encoding: UTF-8
            string: ""
          headers: {}
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Type: 
            - text/html;charset=utf-8
            Content-Length: 
            - "10"
          body: 
            encoding: UTF-8
            string: Hello bazz
          http_version: 
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

    When I run `ruby make_requests.rb Goodbye`
    Then the output should contain:
      """
      Hello foo
      Hello bar
      Hello bazz
      """

