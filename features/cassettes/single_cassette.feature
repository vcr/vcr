@with-bundler
Feature: Single cassette

  Group rspec tests which should use the same cassette, without
  providing a name.  Enable this with the `:single_cassette` option.

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'spec/cassettes'
        c.hook_into :webmock
        c.configure_rspec_metadata!
      end
      """
  Scenario: Use `single_cassette: true`
    Given a file named "spec/single_cassette_spec.rb" with:
      """ruby
      $server = start_sinatra_app do
        get('/') { "Hello" }
      end

      def make_http_request
        Net::HTTP.get_response('localhost', '/', $server.port).body
      end

      require 'spec_helper'

      describe "outermost" do
        describe "outer", vcr: { single_cassette: true } do
          it "uses the same cassette" do
            expect(make_http_request).to eq('Hello')
          end

          describe "inner" do
            it { expect(make_http_request).to eq('Hello') }

            it "uses the same cassette" do
              expect(make_http_request).to eq('Hello')
            end

            it "single cassette is irrelevant when nested", vcr: { single_cassette: true } do
              expect(make_http_request).to eq('Hello')
            end
          end
        end
      end

      """
    When I run `rspec spec/single_cassette_spec.rb`
    Then it should pass with "4 examples, 0 failures"
    And the file "spec/cassettes/outermost/outer.yml" should contain "Hello"
    And the file "spec/cassettes/outermost/outer/uses_the_same_cassette.yml" should not exist
    And the file "spec/cassettes/outermost/outer/inner/uses_the_same_cassette.yml" should not exist

