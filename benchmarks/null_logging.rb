$LOAD_PATH.unshift "./lib"
require 'vcr'
require 'yaml'
require 'open-uri'
require 'benchmark'

VCR.configure do |vcr|
  vcr.cassette_library_dir = './tmp'
  vcr.hook_into :webmock
end

def prepare_cassette
  interactions = 1.upto(100).map do |i|
    VCR::HTTPInteraction.new(
      VCR::Request.new(:get, "http://foo.com/#{i}", "", {}),
      VCR::Response.new(
        VCR::ResponseStatus.new(200, "OK"),
        {}, "Response #{i}", "1.1"
      ),
      Time.now
    ).to_hash
  end

  hash = { "http_interactions" => interactions, "recorded_with" => "VCR #{VCR.version}" }
  VCR.cassette_persisters[:file_system]["logging.yml"] = YAML.dump(hash)
end

prepare_cassette

puts "Ruby #{RUBY_DESCRIPTION}"

3.times do
  puts Benchmark.measure {
    100.downto(50) do |i|
      VCR.use_cassette("logging", :record => :none) do
        open("http://foo.com/#{i}")
      end
    end
  }
end

# Before optimizing null logging:
#
# Ruby ruby 1.9.3p448 (2013-06-27 revision 41675) [x86_64-darwin12.4.0]
#   1.510000   0.010000   1.520000 (  1.523553)
#   1.500000   0.010000   1.510000 (  1.510036)
#   1.500000   0.010000   1.510000 (  1.507076)
#
# After applying the patch from #311 (and forcing `debug_logger` to `nil`:
#
# Ruby ruby 1.9.3p448 (2013-06-27 revision 41675) [x86_64-darwin12.4.0]
#   1.480000   0.020000   1.500000 (  1.500136)
#   1.390000   0.000000   1.390000 (  1.395503)
#   1.400000   0.010000   1.410000 (  1.403931)
#
# After applying my alternate fix:
#
# Ruby ruby 1.9.3p448 (2013-06-27 revision 41675) [x86_64-darwin12.4.0]
#   1.400000   0.010000   1.410000 (  1.410103)
#   1.380000   0.010000   1.390000 (  1.388467)
#   1.360000   0.010000   1.370000 (  1.364418)

