shared_examples_for '.ignore_localhost? deprecation' do
  it 'returns false when no hosts are ignored' do
    VCR::Config.ignored_hosts.should be_empty
    described_class.ignore_localhost?.should be_false
  end

  it 'returns false when only non-local hosts are ignored' do
    VCR::Config.ignore_hosts 'example.com'
    described_class.ignore_localhost?.should be_false
  end

  it 'returns false when only some localhost aliases are ignored' do
    aliases = VCR::LOCALHOST_ALIASES.dup
    aliases.pop
    VCR::Config.ignore_hosts(*aliases)
    described_class.ignore_localhost?.should be_false
  end

  it 'returns true when all localhost aliases are ignored, even if some other hosts are ignored, too' do
    VCR::Config.ignore_hosts 'example.com', *VCR::LOCALHOST_ALIASES
    described_class.ignore_localhost?.should be_true
  end

  it 'prints a warning: WARNING: `VCR::Config.ignore_localhost?` is deprecated.  Check the list of ignored hosts using `VCR::Config.ignored_hosts` instead.' do
    VCR::Config.should_receive(:warn).with(/Check the list of ignored hosts using `VCR::Config.ignored_hosts` instead/)
    described_class.ignore_localhost?
  end
end
