@with-bundler
Feature: Usage with RSpec macro

  VCR provides a macro that makes it easy to use a VCR cassette for an RSpec
  example group.  To use it, simply add `config.extend VCR::RSpec::Macros`
  to your RSpec configuration block.

  In any example group, add a `use_vcr_cassette` declaration to use a cassette
  for that example group.  You can use this in a few different ways:

    - `use_vcr_cassette`
      - Infers a cassette name from the example group description (and parent
        example group descriptions).
      - Uses the `default_cassette_options` you have configured.
    - `use_vcr_cassette "Cassette Name"`
      - Uses the given cassette name.
      - Uses the `default_cassette_options` you have configured.
    - `use_vcr_cassette :cassette => :options`
      - Infers a cassette name from the example group description (and parent
        example group descriptions).
      - Uses the provided cassette options (merged with the defaults).
    - `use_vcr_cassette "Cassette Name", :cassette => :options`
      - Uses the given cassette name.
      - Uses the provided cassette options (merged with the defaults).

  Background:
    Given the following files do not exist:
        | spec/cassettes/VCR-RSpec_integration/without_an_explicit_cassette_name.yml |
        | spec/cassettes/net_http_example.yml                                        |
    And a file named "spec/sinatra_app.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { "Hello" }
      end
      """
    And a file named "spec/vcr_example_spec.rb" with:
      """ruby
      require 'spec_helper'

      describe "VCR-RSpec integration" do
        def make_http_request
          Net::HTTP.get_response('localhost', '/', $server.port).body
        end

        context "without an explicit cassette name" do
          use_vcr_cassette

          it 'records an http request' do
            expect(make_http_request).to eq('Hello')
          end
        end

        context "with an explicit cassette name" do
          use_vcr_cassette "net_http_example"

          it 'records an http request' do
            expect(make_http_request).to eq('Hello')
          end
        end
      end
      """

  Scenario: Use `use_vcr_cassette` macro with RSpec 2
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      require 'sinatra_app'
      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'spec/cassettes'
        c.hook_into :webmock
      end

      RSpec.configure do |c|
        c.extend VCR::RSpec::Macros
      end
      """
    When I run `rspec spec/vcr_example_spec.rb`
    Then the output should contain "2 examples, 0 failures"
     And the file "spec/cassettes/VCR-RSpec_integration/without_an_explicit_cassette_name.yml" should contain "Hello"
     And the file "spec/cassettes/net_http_example.yml" should contain "Hello"
