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
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/foo?a=<%= 'b' * 3 %>
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-type: 
            - text/html;charset=utf-8
            content-length: 
            - "9"
          body: Hello <%= 'bar'.next %>
          http_version: "1.1"
      """
    And a file named "dynamic_erb_example.rb" with:
      """
      require 'vcr'

      VCR.config do |c|
        c.stub_with :fakeweb
        c.cassette_library_dir = 'cassettes'
        c.default_cassette_options = { :record => :none }
      end

      VCR.use_cassette('dynamic', :erb => true) do
        response = Net::HTTP.get_response('example.com', '/foo?a=bbb')
        puts "Response: #{response.body}"
      end
      """
    When I run "ruby dynamic_erb_example.rb"
    Then it should pass with "Response: Hello bas"

  Scenario: Pass arguments to the ERB using :erb => { ... }
    Given a previously recorded cassette file "cassettes/dynamic.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://example.com:80/foo?a=<%= arg1 %>
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-type: 
            - text/html;charset=utf-8
            content-length: 
            - "9"
          body: Hello <%= arg2 %>
          http_version: "1.1"
      """
    And a file named "dynamic_erb_example.rb" with:
      """
      require 'vcr'

      VCR.config do |c|
        c.stub_with :fakeweb
        c.cassette_library_dir = 'cassettes'
        c.default_cassette_options = { :record => :none }
      end

      VCR.use_cassette('dynamic', :erb => { :arg1 => 7, :arg2 => 'baz' }) do
        response = Net::HTTP.get_response('example.com', '/foo?a=7')
        puts "Response: #{response.body}"
      end
      """
    When I run "ruby dynamic_erb_example.rb"
    Then it should pass with "Response: Hello baz"
