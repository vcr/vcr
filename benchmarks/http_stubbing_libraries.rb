require 'rubygems'
require 'benchmark'
require 'net/http'

def http_request
  res = Net::HTTP.get_response(URI.parse('http://example.com'))
  raise "Body should be 'Hello'" unless res.body == 'Hello'
end

def fakeweb
  FakeWeb.register_uri(:get, 'http://example.com', :body => 'Hello')
  yield
ensure
  FakeWeb.clean_registry
end

def webmock
  WebMock.stub_request(:get, 'http://example.com').to_return(:body => 'Hello')
  yield
ensure
  WebMock.reset!
end

def perform_benchmark(name)
  puts "\n\nBenchmarking #{name}:"
  Benchmark.benchmark do |b|
    %w(webmock fakeweb).each do |type|
      b.report(type) do
        # this is a bit convoluted, but we want to ensure that each benchmark runs without the other library loaded,
        # so we fork off a sub-process before requiring the libraries.
        Process.fork do
          require type
          yield type
        end
        Process.wait
      end
    end
  end
end

n = 5000
perform_benchmark("Single setup/teardown") do |type|
  send(type) { n.times { http_request } }
end

perform_benchmark("Setup/teardown for each http request") do |type|
  n.times { send(type) { http_request } }
end

# Output on my machine:
#
# Benchmarking Single setup/teardown:
# webmock  0.000000   0.000000   6.950000 (  6.981525)
# fakeweb  0.000000   0.010000   1.750000 (  1.740679)
#
#
# Benchmarking Setup/teardown for each http request:
# webmock  0.000000   0.000000   7.970000 (  7.981383)
# fakeweb  0.000000   0.000000   2.210000 (  2.203478)
