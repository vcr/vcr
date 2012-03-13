Feature: Decode compressed response

  When the `:decode_compressed_response` option is set to a truthy value, VCR
  will decompress "gzip" and "deflate" response bodies before recording.  This
  ensures that these interactions become readable and editable after being
  serialized.

  This option should be avoided if the actual decompression of response bodies
  is part of the functionality of the library or app being tested.

  Background:
    Given a file named "decompress.rb" with:
      """ruby
      require 'zlib'
      require 'stringio'

      start_sinatra_app(:port => 7777) do
        get('/') {
          content = 'The quick brown fox jumps over the lazy dog'
          io = StringIO.new
          Zlib::GzipWriter.new(io).<<(content).close
          headers['Content-Encoding'] = 'gzip'
          io.string
        }
      end

      require 'vcr'

      VCR.configure do |c|
        c.cassette_library_dir = 'cassettes'
        c.hook_into :fakeweb
      end
      """

  Scenario: The option is not set by default
    When I append to file "decompress.rb":
      """
      VCR.use_cassette(:decompress) do
        Net::HTTP.get_response('localhost', '/', 7777)
      end
      """
    And I run `ruby decompress.rb`
    Then the file "cassettes/decompress.yml" should contain a YAML fragment like:
      """
      content-encoding:
      - gzip
      """

  Scenario: The option is enabled
    When I append to file "decompress.rb":
      """
      VCR.use_cassette(:decompress, :decode_compressed_response => true) do
        Net::HTTP.get_response('localhost', '/', 7777)
      end
      """
    And I run `ruby decompress.rb`
    Then the file "cassettes/decompress.yml" should contain a YAML fragment like:
      """
      content-length:
      - '43'
      """
    And the file "cassettes/decompress.yml" should contain:
      """
      string: The quick brown fox jumps over the lazy dog
      """
