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

  describe "VCR.configure { |c| c.stub_with :faraday }" do
    it 'prints a descriptive warning' do
      Kernel.should_receive(:warn).with(/Just use `VCR::Middleware::Faraday` in your faraday stack/)
      # simulate the loading of the adapter (since it may have already been required)
      load 'vcr/http_stubbing_adapters/faraday.rb'
    end
  end

  describe "VCR::Middleware::Faraday" do
    it 'prints a deprecation warning when passed a block' do
      Kernel.should_receive(:warn).with(/Passing a block .* is deprecated/)
      VCR::Middleware::Faraday.new(stub) { }
    end
  end
end

