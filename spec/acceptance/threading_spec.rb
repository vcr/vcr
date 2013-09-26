require 'spec_helper'

describe VCR do
  context 'when used in a multithreaded environment', :with_monkey_patches => :excon do
    def preload_yaml_serializer_to_avoid_circular_require_warning_race_condition
      VCR.cassette_serializers[:yaml]
    end

    before { preload_yaml_serializer_to_avoid_circular_require_warning_race_condition }

    def recorded_content_for(name)
      VCR.cassette_persisters[:file_system]["#{name}.yml"].to_s
    end

    it 'can use a cassette in an #around_http_request hook', :if => (RUBY_VERSION.to_f > 1.8) do
      VCR.configure do |vcr|
        vcr.around_http_request do |req|
          VCR.use_cassette(req.parsed_uri.path, &req)
        end
      end

      thread = Thread.start do
        Excon.get "http://localhost:#{VCR::SinatraApp.port}/search?q=thread"
      end

      Excon.get "http://localhost:#{VCR::SinatraApp.port}/foo",
        :response_block => Proc.new { thread.join }

      expect(recorded_content_for("search") +
             recorded_content_for("foo")).to include("query: thread", "FOO!")
    end

    def make_multiple_threaded_requests(num_threads)
      VCR.use_cassette("threaded") do
        num_threads.times.map do |i|
          Thread.new do
            Thread.current.abort_on_exception = true
            Excon.get("http://localhost:#{VCR::SinatraApp.port}/search?q=#{i}").body
          end
        end.map(&:value)
      end
    end

    it 'can safely use one cassette across multiple threads' do
      num_threads = 50
      recorded = make_multiple_threaded_requests(num_threads)
      expect(recorded).to eq(num_threads.times.map { |i| "query: #{i}" })

      played_back = make_multiple_threaded_requests(num_threads)
      expect(played_back).to eq(recorded)
    end
  end
end

