shared_examples_for "an http stubbing adapter" do |*args|
  supported_http_libraries = args.shift
  other = args

  before(:each) { VCR.stub!(:http_stubbing_adapter).and_return(subject) }
  subject { described_class }

  describe '.set_http_connections_allowed_to_default' do
    [true, false].each do |default|
      context "when VCR.configuration.allow_http_connections_when_no_cassette is #{default}" do
        before(:each) { VCR.configuration.allow_http_connections_when_no_cassette = default }

        it "sets http_connections_allowed to #{default}" do
          subject.http_connections_allowed = !default
          expect {
            subject.set_http_connections_allowed_to_default
          }.to change { subject.http_connections_allowed? }.from(!default).to(default)
        end
      end
    end
  end

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

