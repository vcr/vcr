Feature: Usage with RSpec metadata

  VCR provides easy integration with RSpec using metadata. To set this
  up, call `configure_rspec_metadata!` in your `VCR.configure` block.

  Once you've done that, you can have an example group or example use
  VCR by passing `:vcr` as an additional argument after the description
  string. It will use set the cassette name based on the example's
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

  Scenario: Use `:vcr` metadata
    Given a file named "spec/vcr_example_spec.rb" with:
      """ruby
      start_sinatra_app(:port => 7777) do
        get('/') { "Hello" }
      end

      def make_http_request
        Net::HTTP.get_response('localhost', '/', 7777).body
      end

      require 'spec_helper'

      describe "VCR example group metadata", :vcr do
        it 'records an http request' do
          make_http_request.should == 'Hello'
        end

        it 'records another http request' do
          make_http_request.should == 'Hello'
        end

        context 'in a nested example group' do
          it 'records another one' do
            make_http_request.should == 'Hello'
          end
        end
      end

      describe "VCR example metadata" do
        it 'records an http request', :vcr do
          make_http_request.should == 'Hello'
        end
      end
      """
    When I run `rspec spec/vcr_example_spec.rb`
    Then it should pass with "4 examples, 0 failures"
     And the file "spec/cassettes/VCR_example_group_metadata/records_an_http_request.yml" should contain "Hello"
     And the file "spec/cassettes/VCR_example_group_metadata/records_another_http_request.yml" should contain "Hello"
     And the file "spec/cassettes/VCR_example_group_metadata/in_a_nested_example_group/records_another_one.yml" should contain "Hello"
     And the file "spec/cassettes/VCR_example_metadata/records_an_http_request.yml" should contain "Hello"

  Scenario: Pass a hash to set the cassette options
    Given a file named "spec/vcr_example_spec.rb" with:
      """ruby
      require 'spec_helper'

      vcr_options = { :cassette_name => "example", :record => :new_episodes }
      describe "Using an options hash", :vcr => vcr_options do
        it 'uses the provided cassette name' do
          VCR.current_cassette.name.should == "example"
        end

        it 'sets the given options' do
          VCR.current_cassette.record_mode.should == :new_episodes
        end
      end
      """
    When I run `rspec spec/vcr_example_spec.rb`
    Then it should pass with "2 examples, 0 failures"
