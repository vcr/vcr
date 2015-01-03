require 'spec_helper'

describe VCR, 'deprecations', :disable_warnings do
  describe ".config" do
    it 'delegates to VCR.configure' do
      expect(VCR).to receive(:configure)
      VCR.config { }
    end

    it 'yields the configuration object' do
      config_object = nil
      VCR.config { |c| config_object = c }
      expect(config_object).to be(VCR.configuration)
    end

    it 'prints a deprecation warning' do
      expect(VCR).to receive(:warn).with(/VCR.config.*deprecated/i)

      VCR.config { }
    end
  end

  describe "Config" do
    it 'returns the same object referenced by VCR.configuration' do
      expect(VCR::Config).to be(VCR.configuration)
    end

    it 'prints a deprecation warning' do
      expect(VCR).to receive(:warn).with(/VCR::Config.*deprecated/i)

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
      expect(VCR::Cassette::MissingERBVariableError).to be(VCR::Errors::MissingERBVariableError)
    end

    it 'prints a deprecation warning' do
      expect(VCR::Cassette).to receive(:warn).with(/VCR::Cassette::MissingERBVariableError.*deprecated/i)

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
      expect(VCR.configuration).to receive(:hook_into).with(:fakeweb, :excon)
      VCR.configure { |c| c.stub_with :fakeweb, :excon }
    end

    it 'prints a deprecation warning' do
      expect(VCR.configuration).to receive(:warn).with(/stub_with.*deprecated/i)
      VCR.configure { |c| c.stub_with :fakeweb, :excon }
    end
  end

  describe "VCR::Middleware::Faraday" do
    it 'prints a deprecation warning when passed a block' do
      expect(Kernel).to receive(:warn).with(/Passing a block .* is deprecated/)
      VCR::Middleware::Faraday.new(double) { }
    end
  end

  describe "VCR::RSpec::Macros" do
    it 'prints a deprecation warning' do
      expect(Kernel).to receive(:warn).with(/VCR::RSpec::Macros is deprecated/)
      Class.new.extend(VCR::RSpec::Macros)
    end
  end
end

