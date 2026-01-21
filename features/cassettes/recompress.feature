Feature: Recompress response

  When the `:recompress_response` option is set to a truthy value, VCR will
  recompress "gzip" and "deflate" response bodies that were previously
  decompressed via `:decode_compressed_response` before playback.

  Background:
    Given a file named "recompress.rb" with:
        """ruby
        require 'zlib'
        require 'stringio'

        $server = start_sinatra_app do
          get('/') {
            content = "The quick brown fox jumps over the lazy dog"
            io = StringIO.new

            writer = Zlib::GzipWriter.new(io)
            writer << content
            writer.close

            headers['Content-Encoding'] = 'gzip'
            io.string
          }
        end

        require 'vcr'

        VCR.configure do |c|
          c.cassette_library_dir = 'cassettes'
          c.hook_into :webmock
          c.default_cassette_options = { :serialize_with => :syck }
          c.filter_sensitive_data('<COLOR>') { 'brown' }
        end

        VCR.use_cassette(:recompress, :decode_compressed_response => true) do
          Net::HTTP.start('localhost', $server.port) do |http|
            http.get('/', 'accept-encoding' => 'identity')
          end
        end
        """

  Scenario: The option is not set by default
    When I append to file "recompress.rb":
      """ruby
      VCR.use_cassette(:recompress) do
        response = Net::HTTP.get_response('localhost', '/', $server.port)
        puts "Content-Encoding: #{response['Content-Encoding'] || 'none'}"
      end
      """
    And I run `ruby recompress.rb`
    Then it should pass with "Content-Encoding: none"

  Scenario: The option is enabled
    When I append to file "recompress.rb":
      """ruby
      VCR.use_cassette(:recompress, :recompress_response => true) do
        response = Net::HTTP.get_response('localhost', '/', $server.port)
        puts "Content-Encoding: #{response['Content-Encoding'] || 'none'}"
      end
      """
    And I run `ruby recompress.rb`
    Then it should pass with "Content-Encoding: gzip"

  Scenario: The recompressing happens after replacing filtered sensitive data
    When I append to file "recompress.rb":
      """ruby
      VCR.use_cassette(:recompress, :recompress_response => true) do
        VCR::Response.decompress(Net::HTTP.get_response('localhost', '/', $server.port).body, 'gzip') do |body|
          puts body
        end
      end
      """
      And I run `ruby recompress.rb`
      Then it should pass with "The quick brown fox jumps over the lazy dog"
