@fakeweb
Feature: RSpec integration
  In order to easily use VCR with RSpec
  As a user of both VCR and RSpec
  I want a simple macro that uses a cassette for an example group

  Scenario: `use_vcr_cassette` macro for RSpec 2
    Given the following files do not exist:
        | cassettes/VCR-RSpec_integration/without_an_explicit_cassette_name.yml |
        | cassettes/net_http_example.yml                                        |
      And a file named "use_vcr_cassette_spec.rb" with:
      """
      require 'vcr/rspec'

      VCR.config do |c|
        c.cassette_library_dir     = 'cassettes'
        c.http_stubbing_library    = :fakeweb
        c.default_cassette_options = { :record => :new_episodes }
      end

      RSpec.configure do |c|
        c.extend VCR::RSpec::Macros
      end

      describe "VCR-RSpec integration" do
        def make_http_request
          Net::HTTP.get_response('example.com', '/').body
        end

        context "without an explicit cassette name" do
          use_vcr_cassette

          it 'records an http request' do
            make_http_request.should =~ /You have reached this web page by typing.*example\.com/
          end
        end

        context "with an explicit cassette name" do
          use_vcr_cassette "net_http_example"

          it 'records an http request' do
            make_http_request.should =~ /You have reached this web page by typing.*example\.com/
          end
        end
      end
      """
    When I run "rspec ./use_vcr_cassette_spec.rb"
    Then the output should contain "2 examples, 0 failures"
     And the file "cassettes/VCR-RSpec_integration/without_an_explicit_cassette_name.yml" should contain "You have reached this web page by typing"
     And the file "cassettes/net_http_example.yml" should contain "You have reached this web page by typing"
