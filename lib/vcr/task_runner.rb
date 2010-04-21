require 'vcr'

module VCR
  module TaskRunner
    extend self

    def migrate_cassettes(dir)
      with_recorded_response_defined do
        FileUtils.cp_r(dir, "#{dir}-backup")

        Dir.glob(dir + '/**/*.yml').each do |cassette_file|
          recorded_responses = YAML.load(File.read(cassette_file))
          next unless recorded_responses.is_a?(Enumerable) && recorded_responses.all? { |rr| rr.is_a?(VCR::RecordedResponse) }

          interactions = recorded_responses.map do |recorded_response|
            http_interaction(recorded_response)
          end

          File.open(cassette_file, 'w') { |f| f.write(interactions.to_yaml) }
        end
      end
    end

    private

    def http_interaction(recorded_response)
      VCR::HTTPInteraction.new(
        request(recorded_response),
        VCR::Response.from_net_http_response(recorded_response.response)
      )
    end

    def request(recorded_response)
      VCR::Request.new(recorded_response.method, recorded_response.uri)
    end

    def with_recorded_response_defined
      VCR.const_set(:RecordedResponse, Class.new(Struct.new(:method, :uri, :response, :request_body, :request_headers)))

      begin
        yield
      ensure
        VCR.send(:remove_const, :RecordedResponse)
      end
    end
  end
end
