require 'spec_helper'

describe VCR, 'deprecations', :disable_warnings do
  describe ".config" do
    it 'delegates to VCR.configure' do
      VCR.should_receive(:configure)
      VCR.config { }
    end

    it 'yields the configuration object' do
      config_object = nil
      VCR.config { |c| config_object = c }
      config_object.should be(VCR.configuration)
    end

    it 'prints a deprecation warning' do
      VCR.should_receive(:warn).with \
        "WARNING: `VCR.config` is deprecated.  Use VCR.configure instead."

      VCR.config { }
    end
  end

  describe "Config" do
    it 'returns the same object referenced by VCR.configuration' do
      VCR::Config.should be(VCR.configuration)
    end

    it 'prints a deprecation warning' do
      VCR.should_receive(:warn).with \
        "WARNING: `VCR::Config` is deprecated.  Use VCR.configuration instead."

      VCR::Config
    end

    it 'preserves the normal undefined constant behavior' do
      expect {
        VCR::SomeUndefinedConstant
      }.to raise_error(NameError)
    end
  end
end
