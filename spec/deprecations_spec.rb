require 'spec_helper'

describe 'Deprecations' do
  disable_warnings

  describe VCR::Config do
    describe '.http_stubbing_library' do
      before(:each) { described_class.stub_with :webmock, :typhoeus }

      it 'returns the first configured stubbing library' do
        described_class.http_stubbing_library.should == :webmock
      end

      it 'prints a warning: WARNING: VCR::Config.http_stubbing_library is deprecated.  Use VCR::Config.http_stubbing_libraries instead' do
        described_class.should_receive(:warn).with("WARNING: `VCR::Config.http_stubbing_library` is deprecated.  Use `VCR::Config.http_stubbing_libraries` instead.")
        described_class.http_stubbing_library
      end
    end

    describe '.http_stubbing_library=' do
      it 'sets http_stubbing_libraries to an array of the given value' do
        described_class.http_stubbing_library = :webmock
        described_class.http_stubbing_libraries.should == [:webmock]
      end

      it 'prints a warning: WARNING: VCR::Config.http_stubbing_library= is deprecated.  Use VCR::Config.stub_with instead' do
        described_class.should_receive(:warn).with("WARNING: `VCR::Config.http_stubbing_library = :webmock` is deprecated.  Use `VCR::Config.stub_with :webmock` instead.")
        described_class.http_stubbing_library = :webmock
      end
    end
  end

  describe VCR::Cassette do
    subject { VCR::Cassette.new('cassette name') }

    it 'raises an error when an :allow_real_http lambda is given' do
      expect { VCR::Cassette.new('cassette name', :allow_real_http => lambda {}) }.to raise_error(ArgumentError)
    end

    it "prints a warning: WARNING: VCR::Cassette#allow_real_http_requests_to? is deprecated and should no longer be used" do
      subject.should_receive(:warn).with("WARNING: VCR::Cassette#allow_real_http_requests_to? is deprecated and should no longer be used.")
      subject.allow_real_http_requests_to?(URI.parse('http://example.org'))
    end

    [true, false].each do |orig_ignore_localhost|
      context "when the http_stubbing_adapter's ignore_localhost is set to #{orig_ignore_localhost}" do
        before(:each) { VCR.http_stubbing_adapter.ignore_localhost = orig_ignore_localhost }

        context 'when the :allow_real_http option is set to :localhost' do
          subject { VCR::Cassette.new('cassette name', :allow_real_http => :localhost) }

          it "sets the http_stubbing_adapter's ignore_localhost attribute to true" do
            subject
            VCR.http_stubbing_adapter.ignore_localhost?.should be_true
          end

          it "prints a warning: VCR's :allow_real_http cassette option is deprecated.  Instead, use the ignore_localhost configuration option." do
            Kernel.should_receive(:warn).with("WARNING: VCR's :allow_real_http cassette option is deprecated.  Instead, use the ignore_localhost configuration option.")
            subject
          end

          it "reverts ignore_localhost when the cassette is ejected" do
            subject.eject
            VCR.http_stubbing_adapter.ignore_localhost?.should == orig_ignore_localhost
          end

          {
            'http://localhost'   => true,
            'http://127.0.0.1'   => true,
            'http://example.com' => false
          }.each do |url, expected_value|
            it "returns #{expected_value} for #allow_real_http_requests_to? when it is given #{url}" do
              subject.allow_real_http_requests_to?(URI.parse(url)).should == expected_value
            end
          end
        end
      end
    end
  end
end
