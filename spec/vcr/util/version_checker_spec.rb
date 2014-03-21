require 'spec_helper'

module VCR
  describe VersionChecker do
    it 'raises an error if the major version is too low' do
      checker = VersionChecker.new('foo', '0.7.3', '1.0.0')
      expect { checker.check_version! }.to raise_error(Errors::LibraryVersionTooLowError)
    end

    it 'raises an error if the minor version is too low' do
      checker = VersionChecker.new('foo', '1.0.99', '1.1.3')
      expect { checker.check_version! }.to raise_error(Errors::LibraryVersionTooLowError)
    end

    it 'raises an error if the patch version is too low' do
      checker = VersionChecker.new('foo', '1.0.8', '1.0.10')
      expect { checker.check_version! }.to raise_error(Errors::LibraryVersionTooLowError)
    end

    it 'does not raise an error when the version is equal' do
      checker = VersionChecker.new('foo', '1.0.0', '1.0.0')
      expect { checker.check_version! }.not_to raise_error
    end

    it 'does not raise an error when the version is higher' do
      checker = VersionChecker.new('foo', '2.0.0', '1.0.0')
      expect { checker.check_version! }.not_to raise_error
    end
  end
end

