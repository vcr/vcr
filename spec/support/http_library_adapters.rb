module HeaderDowncaser
  def downcase_headers(headers)
    {}.tap do |downcased|
      headers.each do |k, v|
        downcased[k.downcase] = v
      end
    end
  end
end

HTTP_LIBRARY_ADAPTERS = {}

HTTP_LIBRARY_ADAPTERS['net/http'] = Module.new do
  include HeaderDowncaser

  def self.http_library_name; 'Net::HTTP'; end

  def get_body_string(response); response.body; end
  alias get_body_object get_body_string

  def get_header(header_key, response)
    response.get_fields(header_key)
  end

  def make_http_request(method, url, body = nil, headers = {})
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.send_request(method.to_s.upcase, uri.request_uri, body, headers)
  end

  DEFAULT_REQUEST_HEADERS = { "Accept"=>["*/*"] }
  DEFAULT_REQUEST_HEADERS['User-Agent'] = ["Ruby"] if RUBY_VERSION.to_f > 1.8
  DEFAULT_REQUEST_HEADERS['Accept-Encoding'] = ["gzip;q=1.0,deflate;q=0.6,identity;q=0.3"] if RUBY_VERSION.to_f > 1.9

  def normalize_request_headers(headers)
    defined?(super) ? super :
    downcase_headers(headers.merge(DEFAULT_REQUEST_HEADERS))
  end
end

HTTP_LIBRARY_ADAPTERS['patron'] = Module.new do
  def self.http_library_name; 'Patron'; end

  def get_body_string(response); response.body; end
  alias get_body_object get_body_string

  def get_header(header_key, response)
    response.headers[header_key]
  end

  def make_http_request(method, url, body = nil, headers = {})
    Patron::Session.new.request(method, url, headers, :data => body || '')
  end

  def normalize_request_headers(headers)
    headers.merge('Expect' => [''])
  end
end

HTTP_LIBRARY_ADAPTERS['httpclient'] = Module.new do
  def self.http_library_name; 'HTTP Client'; end

  def get_body_string(response)
    body = response.body
    string = body.is_a?(String) ? body : body.content
    string.respond_to?(:read) ? string.read : string
  end

  def get_body_object(response)
    response.body
  end

  def get_header(header_key, response)
    response.header[header_key]
  end

  def make_http_request(method, url, body = nil, headers = {})
    HTTPClient.new.request(method, url, nil, body, headers)
  end

  def normalize_request_headers(headers)
    headers.merge({
      'Accept'     => ["*/*"],
      'User-Agent' => ["HTTPClient/1.0 (#{HTTPClient::VERSION}, ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}))"],
      'Date'       => [Time.now.httpdate]
    })
  end
end

HTTP_LIBRARY_ADAPTERS['em-http-request'] = Module.new do
  def self.http_library_name; 'EM HTTP Request'; end

  def get_body_string(response)
    response.response
  end
  alias get_body_object get_body_string

  def get_header(header_key, response)
    values = response.response_header[header_key.upcase.gsub('-', '_')]
    values.is_a?(Array) ? values : values.split(', ')
  end

  def make_http_request(method, url, body = nil, headers = {})
    http = nil
    EventMachine.run do
      http = EventMachine::HttpRequest.new(url).send(method, :body => body, :head => headers)
      http.callback { EventMachine.stop }
    end
    http
  end

  def normalize_request_headers(headers)
    headers
  end
end

HTTP_LIBRARY_ADAPTERS['curb'] = Module.new do
  def self.http_library_name; "Curb"; end

  def get_body_string(response)
    response.body_str
  end
  alias get_body_object get_body_string

  def get_header(header_key, response)
    headers = response.header_str.split("\r\n")[1..-1]
    value = nil
    headers.each do |h|
      next unless h =~ /^#{Regexp.escape(header_key)}: (.*)$/
      new_value = $1.split(', ')
      value = value ? Array(value) + Array(new_value) : new_value
    end
    value
  end

  def make_http_request(method, url, body = nil, headers = {})
    Curl::Easy.new(url) do |c|
      c.headers = headers

      if [:post, :put].include?(method)
        c.send("http_#{method}", body)
      else
        c.send("http_#{method}")
      end
    end
  end

  def normalize_request_headers(headers)
    headers
  end
end

HTTP_LIBRARY_ADAPTERS['typhoeus'] = Module.new do
  def self.http_library_name; "Typhoeus"; end

  def get_body_string(response)
    response.body
  end
  alias get_body_object get_body_string

  def get_header(header_key, response)
    # Due to https://github.com/typhoeus/typhoeus/commit/256c95473d5d40d7ec2f5db603687323ddd73689
    # headers are now downcased.
    # ...except when they're not.  I'm not 100% why (I haven't had time to dig into it yet)
    # but in some situations the headers aren't downcased.  I think it has to do with playback; VCR
    # isn't sending the headers in downcased to typhoeus. It gets complicated with the interaction
    # w/ WebMock, and the fact that webmock normalizes headers in a different fashion.
    #
    # For now this hack works.
    response.headers.fetch(header_key.downcase) { response.headers[header_key] }
  end

  def make_http_request(method, url, body = nil, headers = {})
    request = Typhoeus::Request.new(url, :method => method, :body => body, :headers => headers)
    request.run
    request.response
  end

  def normalize_request_headers(headers)
    headers.merge("User-Agent"=>["Typhoeus - https://github.com/typhoeus/typhoeus"])
  end
end

HTTP_LIBRARY_ADAPTERS['typhoeus 0.4'] = Module.new do
  def self.http_library_name; "Typhoeus"; end

  def get_body_string(response)
    response.body
  end
  alias get_body_object get_body_string

  def get_header(header_key, response)
    response.headers_hash[header_key]
  end

  def make_http_request(method, url, body = nil, headers = {})
    Typhoeus::Request.send(method, url, :body => body, :headers => headers)
  end

  def normalize_request_headers(headers)
    headers
  end
end

HTTP_LIBRARY_ADAPTERS['excon'] = Module.new do
  def self.http_library_name; "Excon"; end

  def get_body_string(response)
    response.body
  end
  alias get_body_object get_body_string

  def get_header(header_key, response)
    response.headers[header_key]
  end

  def make_http_request(method, url, body = nil, headers = {})
    # There are multiple ways to use Excon but this is how fog (the main user of excon) uses it:
    # https://github.com/fog/fog/blob/v1.1.1/lib/fog/aws/rds.rb#L139-147
    Excon.new(url).request(:method => method.to_s.upcase, :body => body, :headers => headers)
  end

  def normalize_request_headers(headers)
    headers.merge('User-Agent' => [Excon::USER_AGENT])
  end
end

%w[ net_http typhoeus patron ].each do |_faraday_adapter|
  if _faraday_adapter == 'typhoeus' &&
     defined?(::Typhoeus::VERSION) &&
     ::Typhoeus::VERSION.to_f >= 0.5
    require 'typhoeus/adapters/faraday'
  end

  HTTP_LIBRARY_ADAPTERS["faraday (w/ #{_faraday_adapter})"] = Module.new do
    class << self; self; end.class_eval do
      define_method(:http_library_name) do
        "Faraday (#{_faraday_adapter})"
      end
    end

    define_method(:faraday_adapter) { _faraday_adapter.to_sym }

    def get_body_string(response)
      response.body
    end
    alias get_body_object get_body_string

    def get_header(header_key, response)
      value = response.headers[header_key]
      value.split(', ') if value
    end

    def make_http_request(method, url, body = nil, headers = {})
      url_root, url_rest = split_url(url)

      faraday_connection(url_root).send(method) do |req|
        req.url url_rest
        headers.each { |k, v| req[k] = v }
        req.body = body if body
      end
    end

    def split_url(url)
      uri = URI.parse(url)
      url_root = "#{uri.scheme}://#{uri.host}:#{uri.port}"
      rest = url.sub(url_root, '')

      [url_root, rest]
    end

    def faraday_connection(url_root)
      Faraday::Connection.new(:url => url_root) do |builder|
        builder.adapter faraday_adapter
      end
    end

    def normalize_request_headers(headers)
      headers.merge("User-Agent" => ["Faraday v#{Faraday::VERSION}"])
    end
  end
end

