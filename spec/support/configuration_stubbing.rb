shared_context "configuration stubbing" do
  let(:config) { double("VCR::Configuration", force_utf8_encoding?: false) }

  before do
    allow(VCR).to receive(:configuration) { config }
  end
end

