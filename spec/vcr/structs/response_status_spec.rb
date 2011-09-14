require 'spec_helper'

describe VCR::ResponseStatus do
  it_performs 'status message normalization' do
    def instance(message)
      described_class.new(200, message)
    end
  end
end
