require 'spec_helper'

RSpec.describe VCR do
  context 'when used in a multithreaded environment', :with_monkey_patches => :excon do
    def preload_yaml_serializer_to_avoid_circular_require_warning_race_condition
      VCR.cassette_serializers[:yaml]
    end

    before { preload_yaml_serializer_to_avoid_circular_require_warning_race_condition }

    def recorded_content_for(name)
      VCR.cassette_persisters[:file_system]["#{name}.yml"].to_s
    end

    it 'can use a cassette in an #around_http_request hook' do
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

    it 'can turn off VCR after another thread has started and affect the new thread' do
      # Trigger context in main thread
      VCR.turned_on?

      thread = Thread.start do
        # Trigger VCR to dup context to this new thread, linked to main thread
        VCR.turned_on?

        # Stop processing this thread so we can turn off VCR on the main thread
        Thread.stop

        # This request should be made after VCR is turned off on the main thread
        Excon.get "http://localhost:#{VCR::SinatraApp.port}"
      end

      # Ensure the other thread has a chance to stop before we proceed?
      sleep 1

      VCR.turned_off do
        # Now that VCR is turned off, we can resume our other thread
        thread.wakeup

        # Ensure the other thread has a chance to resume before we proceed?
        sleep 1
      end

      thread.join
    end

    it 'can turn on VCR in a new thread' do
      VCR.turn_off!

      Thread.new do
        expect { VCR.turn_on! }.to change { VCR.turned_on? }.from(false).to(true)
      end.join

      expect(VCR.turned_on?).to eq(false)
    end

    it 'can turn on VCR in a new thread' do
      expect(VCR.turned_on?).to eq(true)

      Thread.new do
        expect { VCR.turn_off! }.to change { VCR.turned_on? }.from(true).to(false)
      end.join

      expect(VCR.turned_on?).to eq(true)
    end
  end
end
