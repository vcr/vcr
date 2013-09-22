shared_context "configuration stubbing" do
  let(:config) { double("VCR::Configuration") }

  before do
    allow(VCR).to receive(:configuration) { config }
  end
end

