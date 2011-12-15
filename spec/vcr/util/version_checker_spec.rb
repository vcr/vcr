require 'spec_helper'

module VCR
  describe VersionChecker do
    it 'does not raise an error or print a warning when the min_patch is 0.6.5, the max_minor is 0.7 and the version is 0.7.3' do
      checker = VersionChecker.new('foo', '0.7.3', '0.6.5', '0.7')
      Kernel.should_not_receive(:warn)
      checker.check_version!
    end
  end
end

