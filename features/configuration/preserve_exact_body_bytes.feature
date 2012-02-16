@exclude-18
Feature: Preserve Exact Body Bytes

  Some HTTP servers are not well-behaved and respond with invalid data: the response body may
  not be encoded according to the encoding specified in the HTTP headers, or there may be bytes
  that are invalid for the given encoding. The YAML and JSON serializers are not generally
  designed to handle these cases gracefully, and you may get errors when the cassette is serialized
  or deserialized. Also, the encoding may not be preserved when round-tripped through the
  serializer.

  VCR provides a configuration option to deal with cases like these. The `preserve_exact_body_bytes`
  method accepts a block that VCR will use to determine if the body of the given request or response object
  should be base64 encoded in order to preserve the bytes exactly as-is. VCR does not do this by
  default, since base64-encoding the string removes the human readibility.

  Scenario: Preserve exact bytes for response body with invalid encoding
    Given a file named "preserve.rb" with:
      """ruby
      # encoding: utf-8
      string = "abc \xFA"
      puts "Valid encoding: #{string.valid_encoding?}"

      start_sinatra_app(:port => 7777) do
        get('/') { string }
      end

      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'cassettes'
        c.hook_into :fakeweb
        c.preserve_exact_body_bytes do |http_message|
          http_message.body.encoding.name == 'ASCII-8BIT' ||
          !http_message.body.valid_encoding?
        end
      end

      def make_request(label)
        puts
        puts label
        VCR.use_cassette('example', :serialize_with => :json) do
          body = Net::HTTP.get_response(URI("http://localhost:7777/")).body
          puts "Body: #{body.inspect}"
        end
      end

      make_request("Recording:")
      make_request("Playback:")
      """
    When I run `ruby preserve.rb`
    Then the output should contain exactly:
      """
      Valid encoding: false

      Recording:
      Body: "abc \xFA"

      Playback:
      Body: "abc \xFA"

      """
    And the file "cassettes/example.json" should contain:
      """
      "body":{"encoding":"ASCII-8BIT","base64_string":"YWJjIPo=\n"}
      """

