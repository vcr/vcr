Feature: Dynamic ERB cassettes

  By default, cassettes are static: the exact response that was received
  when the cassette was recorded will be replayed for all future requests.
  Usually, this is fine, but in some cases you need something more dynamic.
  You can use ERB for this.

  To enable ERB evaluation of a cassette, pass the `:erb => true` option
  to a cassette.  If you want to pass variables to the cassette, you can
  pass the names and values of the variables in a hash (`:erb => { ... }`).

  Scenario: Enable dynamic ERB cassette evalutation using :erb => true
    Given a previously recorded cassette file "cassettes/dynamic.yml" with:
      """
      ---
      http_interactions:
      - request:
          method: get
          uri: http://example.com/foo?a=<%= 'b' * 3 %>
          body:
            encoding: UTF-8
            string: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Type:
            - text/html;charset=utf-8
            Content-Length:
            - '9'
          body:
            encoding: UTF-8
            string: Hello <%= 'bar'.next %>
          http_version: '1.1'
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """
    And a file named "dynamic_erb_example.rb" with:
      """ruby
      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('dynamic', :erb => true) do
        response = Net::HTTP.get_response('example.com', '/foo?a=bbb')
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby dynamic_erb_example.rb`
    Then it should pass with "Response: Hello bas"

  Scenario: Pass arguments to the ERB using :erb => { ... }
    Given a previously recorded cassette file "cassettes/dynamic.yml" with:
      """
      ---
      http_interactions:
      - request:
          method: get
          uri: http://example.com/foo?a=<%= arg1 %>
          body:
            encoding: UTF-8
            string: ''
          headers: {}
        response:
          status:
            code: 200
            message: OK
          headers:
            Content-Type:
            - text/html;charset=utf-8
            Content-Length:
            - '9'
          body:
            encoding: UTF-8
            string: Hello <%= arg2 %>
          http_version: '1.1'
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """
    And a file named "dynamic_erb_example.rb" with:
      """ruby
      require 'vcr'

      VCR.configure do |c|
        c.hook_into :webmock
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('dynamic', :erb => { :arg1 => 7, :arg2 => 'baz' }) do
        response = Net::HTTP.get_response('example.com', '/foo?a=7')
        puts "Response: #{response.body}"
      end
      """
    When I run `ruby dynamic_erb_example.rb`
    Then it should pass with "Response: Hello baz"
