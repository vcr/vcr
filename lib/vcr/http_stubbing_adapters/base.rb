module VCR
  module HttpStubbingAdapters
    autoload :FakeWeb, 'vcr/http_stubbing_adapters/fakeweb'

    class Base
      class << self
        def with_http_connections_allowed_set_to(value)
          original_value = http_connections_allowed?
          self.http_connections_allowed = value
          begin
            yield
          ensure
            self.http_connections_allowed = original_value
          end
        end
      end
    end
  end
end
