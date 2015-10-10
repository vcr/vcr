require 'spec_helper'

describe VCR do
  def recorded_content_for(name)
    VCR.cassette_persisters[:file_system]["#{name}.yml"].to_s
  end

  context 'when used in a multithreaded environment with an around_http_request', :with_monkey_patches => :excon do
    def preload_yaml_serializer_to_avoid_circular_require_warning_race_condition
      VCR.cassette_serializers[:yaml]
    end

    before { preload_yaml_serializer_to_avoid_circular_require_warning_race_condition }

    it 'can use a cassette in an #around_http_request hook', :if => (RUBY_VERSION.to_f > 1.8) do
      VCR.configure do |vcr|
        vcr.around_http_request do |req|
          VCR.use_cassette(req.parsed_uri.path, &req)
        end
      end

      threads = 50.times.map do
        Thread.start do
          Excon.get "http://localhost:#{VCR::SinatraApp.port}/search?q=thread"
        end
      end
      Excon.get "http://localhost:#{VCR::SinatraApp.port}/foo"
      threads.each(&:join)

      expect(recorded_content_for("search") +
             recorded_content_for("foo")).to include("query: thread", "FOO!")
    end
  end

  context 'when used in a multithreaded environment with a cassette', :with_monkey_patches => :excon do
    it 'properly stubs threaded requests' do
      VCR.use_cassette('/foo') do
        threads = 50.times.map do
          Thread.start do
            Excon.get "http://localhost:#{VCR::SinatraApp.port}/foo"
          end
        end
        threads.each(&:join)
      end

      expect(
        recorded_content_for("foo")).to include("FOO!")
    end
  end
end

