require 'spec_helper'

describe 'Deprecations' do
  describe VCR::Cassette do
    disable_warnings
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
            VCR.http_stubbing_adapter.ignore_localhost.should be_true
          end

          it "prints a warning: VCR's :allow_real_http cassette option is deprecated.  Instead, use the ignore_localhost configuration option." do
            Kernel.should_receive(:warn).with("WARNING: VCR's :allow_real_http cassette option is deprecated.  Instead, use the ignore_localhost configuration option.")
            subject
          end

          it "reverts ignore_localhost when the cassette is ejected" do
            subject.eject
            VCR.http_stubbing_adapter.ignore_localhost.should == orig_ignore_localhost
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