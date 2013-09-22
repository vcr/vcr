module VCRStubHelpers
  def interactions_from(file)
    hashes = YAML.load_file(File.join(VCR::SPEC_ROOT, 'fixtures', file))['http_interactions']
    hashes.map { |h| VCR::HTTPInteraction.from_hash(h) }
  end

  def stub_requests(*args)
    allow(VCR).to receive(:http_interactions).and_return(VCR::Cassette::HTTPInteractionList.new(*args))
  end

  def http_interaction(url, response_body = "FOO!", status_code = 200)
    request = VCR::Request.new(:get, request_url)
    response_status = VCR::ResponseStatus.new(status_code)
    response = VCR::Response.new(response_status, nil, response_body, '1.1')
    VCR::HTTPInteraction.new(request, response)
  end
end
