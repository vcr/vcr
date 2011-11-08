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

  describe "Cassette::MissingERBVariableError" do
    it 'returns VCR::Errors::MissingERBVariableError' do
      VCR::Cassette::MissingERBVariableError.should be(VCR::Errors::MissingERBVariableError)
    end

    it 'prints a deprecation warning' do
      VCR::Cassette.should_receive(:warn).with \
        "WARNING: `VCR::Cassette::MissingERBVariableError` is deprecated.  Use `VCR::Errors::MissingERBVariableError` instead."

      VCR::Cassette::MissingERBVariableError
    end

    it 'preserves the normal undefined constant behavior' do
      expect {
        VCR::Cassette::SomeUndefinedConstant
      }.to raise_error(NameError)
    end
  end

  describe "VCR.configure { |c| c.stub_with ... }" do
    it 'delegates to #hook_into' do
      VCR.configuration.should_receive(:hook_into).with(:fakeweb, :excon)
      VCR.configure { |c| c.stub_with :fakeweb, :excon }
    end

    it 'prints a deprecation warning' do
      VCR.configuration.should_receive(:warn).with \
        "WARNING: `VCR.config { |c| c.stub_with ... }` is deprecated. Use `VCR.configure { |c| c.hook_into ... }` instead."

      VCR.configure { |c| c.stub_with :fakeweb, :excon }
    end
  end

  describe "VCR::Middleware::Faraday" do
    it 'prints a deprecation warning when passed a block' do
      Kernel.should_receive(:warn).with(/Passing a block .* is deprecated/)
      VCR::Middleware::Faraday.new(stub) { }
    end
  end
end

