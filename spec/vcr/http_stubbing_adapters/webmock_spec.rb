require 'spec_helper'

describe VCR::HttpStubbingAdapters::WebMock, :without_monkey_patches => :vcr do
  it_behaves_like 'an http stubbing adapter',
    %w[net/http patron httpclient em-http-request curb],
    [:method, :uri, :host, :path, :body, :headers]

  it_performs('version checking',
    :valid    => %w[ 1.6.0 1.6.99 ],
    :too_low  => %w[ 0.9.9 0.9.10 0.1.30 1.0.30 1.2.9 1.3.9 ],
    :too_high => %w[ 1.7.0 1.10.0 2.0.0 ]
  ) do
    def stub_version(version)
      WebMock.stub(:version).and_return(version)
    end
  end
end
