@with-bundler
Feature: Usage with RSpec metadata

  VCR provides easy integration with RSpec using metadata. To set this
  up, call `configure_rspec_metadata!` in your `VCR.configure` block.

  Once you've done that, you can have an example group or example use
  VCR by passing `:vcr` as an additional argument after the description
  string. It will set the cassette name based on the example's
  full description.

  If you need to override the cassette name or options, you can pass a
  hash (`:vcr => { ... }`).

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'spec/cassettes'
        c.hook_into :webmock
        c.configure_rspec_metadata!
      end

      RSpec.configure do |c|
        # so we can use `:vcr` rather than `:vcr => true`;
        # in RSpec 3 this will no longer be necessary.
        c.treat_symbols_as_metadata_keys_with_true_values = true
      end
      """
    And a previously recorded cassette file "spec/cassettes/Group/optionally_raises_an_error.yml" with:
      """
      --- 
      http_interactions: 
      - request: 
          method: get
          uri: http://example.com/foo
          body: 
            encoding: UTF-8
            string: ""
          headers: {}
        response: 
          status: 
            code: 200
            message: OK
          headers: 
            Content-Length: 
            - "5"
          body: 
            encoding: UTF-8
            string: Hello
          http_version: "1.1"
        recorded_at: Tue, 01 Nov 2011 04:58:44 GMT
      recorded_with: VCR 2.0.0
      """

  Scenario: Use `:vcr` metadata
    Given a file named "spec/vcr_example_spec.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { "Hello" }
      end

      def make_http_request
        Net::HTTP.get_response('localhost', '/', $server.port).body
      end

      require 'spec_helper'

      describe "VCR example group metadata", :vcr do
        it 'records an http request' do
          expect(make_http_request).to eq('Hello')
        end

        it 'records another http request' do
          expect(make_http_request).to eq('Hello')
        end

        context 'in a nested example group' do
          it 'records another one' do
            expect(make_http_request).to eq('Hello')
          end
        end
      end

      describe "VCR example metadata" do
        it 'records an http request', :vcr do
          expect(make_http_request).to eq('Hello')
        end
      end
      """
    When I run `rspec spec/vcr_example_spec.rb`
    Then it should pass with "4 examples, 0 failures"
     And the file "spec/cassettes/VCR_example_group_metadata/records_an_http_request.yml" should contain "Hello"
     And the file "spec/cassettes/VCR_example_group_metadata/records_another_http_request.yml" should contain "Hello"
     And the file "spec/cassettes/VCR_example_group_metadata/in_a_nested_example_group/records_another_one.yml" should contain "Hello"
     And the file "spec/cassettes/VCR_example_metadata/records_an_http_request.yml" should contain "Hello"

  Scenario: `:allow_unused_http_interactions => false` causes a failure if there are unused interactions
    And a file named "spec/vcr_example_spec.rb" with:
      """ruby
      require 'spec_helper'

      describe "Group", :vcr => { :allow_unused_http_interactions => false } do
        it 'optionally raises an error' do
          # don't fail
        end
      end
      """
    When I run `rspec spec/vcr_example_spec.rb`
    Then it should fail with an error like:
      """
      There are unused HTTP interactions left in the cassette:
        - [get http://example.com/foo] => [200 "Hello"]
      """

  Scenario: `:allow_unused_http_interactions => false` does not raise if the example already failed
    And a file named "spec/vcr_example_spec.rb" with:
      """ruby
      require 'spec_helper'

      describe "Group", :vcr => { :allow_unused_http_interactions => false } do
        it 'optionally raises an error' do
          raise "boom"
        end
      end
      """
    When I run `rspec spec/vcr_example_spec.rb`
    Then it should fail with "boom"
     And the output should not contain "There are unused HTTP interactions"

  Scenario: Pass a hash to set the cassette options
    Given a file named "spec/vcr_example_spec.rb" with:
      """ruby
      require 'spec_helper'

      vcr_options = { :cassette_name => "example", :record => :new_episodes }
      describe "Using an options hash", :vcr => vcr_options do
        it 'uses the provided cassette name' do
          expect(VCR.current_cassette.name).to eq("example")
        end

        it 'sets the given options' do
          expect(VCR.current_cassette.record_mode).to eq(:new_episodes)
        end
      end
      """
    When I run `rspec spec/vcr_example_spec.rb`
    Then it should pass with "2 examples, 0 failures"
