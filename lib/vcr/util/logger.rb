module VCR
  # @private
  module Logger
    def log(message, indentation_level = 0)
      return unless logger
      indentation = '  ' * indentation_level
      log_message = indentation + log_prefix + message
      logger.puts log_message
    end

    def log_prefix
      return unless logger
      ''
    end

    def request_summary(request, request_matchers)
      return unless logger
      attributes = [request.method, request.uri]
      attributes << request.body.to_s[0, 80].inspect if request_matchers.include?(:body)
      attributes << request.headers.inspect          if request_matchers.include?(:headers)
      "[#{attributes.join(" ")}]"
    end

    def response_summary(response)
      return unless logger
      "[#{response.status.code} #{response.body[0, 80].inspect}]"
    end

    def logger
      @logger ||= VCR.configuration.debug_logger
    end
  end
end
