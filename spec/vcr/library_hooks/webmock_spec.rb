require 'spec_helper'

describe "WebMock hook", :with_monkey_patches => :webmock do
  %w[net/http patron httpclient em-http-request curb typhoeus].each do |lib|
    it_behaves_like 'a hook into an HTTP library', lib do
      if lib == 'net/http'
        def normalize_request_headers(headers)
          headers.merge(DEFAULT_REQUEST_HEADERS)
        end
      end
    end
  end

  it_performs('version checking', 'WebMock',
    :valid    => %w[ 1.7.0 1.7.99 ],
    :too_low  => %w[ 0.9.9 0.9.10 0.1.30 1.0.30 1.6.9 ],
    :too_high => %w[ 1.8.0 1.10.0 2.0.0 ]
  ) do

    def stub_callback_registration
      ::WebMock.stub(:after_request)
    end

    def stub_version(version)
      WebMock.stub(:version).and_return(version)
    end
  end
end
