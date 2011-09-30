shared_examples_for "an http stubbing adapter" do |*args|
  supported_http_libraries = args.shift
  other = args

  before(:each) { VCR.stub!(:http_stubbing_adapter).and_return(subject) }
  subject { described_class }

  describe '.exclusively_enabled' do
    def adapter_enabled?(adapter)
      enabled = nil
      subject.exclusively_enabled { enabled = adapter.enabled? }
      enabled
    end

    VCR::HttpStubbingAdapters::Common.adapters.each do |adapter|
      if adapter == described_class
        it "yields with #{adapter} enabled" do
          adapter_enabled?(adapter).should eq(true)
        end
      else
        it "yields without #{adapter} enabled" do
          adapter_enabled?(adapter).should eq(false)
        end
      end
    end

    it 're-enables all adapters afterwards' do
      VCR::HttpStubbingAdapters::Common.adapters.each { |a| a.should be_enabled }
      subject.exclusively_enabled { }
      VCR::HttpStubbingAdapters::Common.adapters.each { |a| a.should be_enabled }
    end
  end

  Array(supported_http_libraries).each do |library|
    it_behaves_like 'an http library', library, *other
  end
end

