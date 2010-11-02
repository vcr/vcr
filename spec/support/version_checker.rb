shared_examples_for "version checking" do |options|
  library = described_class.library_name

  describe '#check_version!' do
    options[:valid].each do |version|
      it "does nothing when #{library}'s version is #{version}" do
        stub_version(version)
        described_class.should_not_receive(:warn)
        expect { described_class.check_version! }.to_not raise_error
      end
    end

    options[:too_low].each do |version|
      it "raises an error when #{library}'s version is #{version}" do
        stub_version(version)
        described_class.should_not_receive(:warn)
        expect { described_class.check_version! }.to raise_error(/You are using #{library} #{version}.  VCR requires version/)
      end
    end

    options[:too_high].each do |version|
      it "does nothing when #{library}'s version is #{version}" do
        stub_version(version)
        described_class.should_receive(:warn).with(/VCR is known to work with #{library}/)
        expect { described_class.check_version! }.to_not raise_error
      end
    end
  end
end
