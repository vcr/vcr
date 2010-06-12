require 'spec_helper'

describe 'Deprecations' do
  describe VCR do
    subject { VCR }
    deprecated :create_cassette!,  :insert_cassette, "WARNING: VCR.create_cassette! is deprecated.  Instead, use: VCR.insert_cassette."
    deprecated :destroy_cassette!, :eject_cassette,  "WARNING: VCR.destroy_cassette! is deprecated.  Instead, use: VCR.eject_cassette."
    deprecated :with_cassette,     :use_cassette,    "WARNING: VCR.with_cassette is deprecated.  Instead, use: VCR.use_cassette."
  end

  describe VCR::Cassette do
    disable_warnings
    subject { VCR::Cassette.new('cassette name') }
    deprecated :destroy!,   :eject, "WARNING: VCR::Cassette#destroy! is deprecated.  Instead, use: VCR::Cassette#eject."
    deprecated :cache_file, :file,  "WARNING: VCR::Cassette#cache_file is deprecated.  Instead, use: VCR::Cassette#file."

    it 'delegates the :unregistered record option to :new_episodes' do
      cassette = VCR::Cassette.new('cassette name', :record => :unregistered)
      cassette.record_mode.should == :new_episodes
    end

    it "prints a warning: WARNING: VCR's :unregistered record mode is deprecated.  Instead, use: :new_episodes." do
      Kernel.should_receive(:warn).with("WARNING: VCR's :unregistered record mode is deprecated.  Instead, use: :new_episodes.")
      VCR::Cassette.new('cassette name', :record => :unregistered)
    end

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

  describe VCR::Config do
    disable_warnings
    subject { VCR::Config }
    deprecated :cache_dir,  :cassette_library_dir,  "WARNING: VCR::Config.cache_dir is deprecated.  Instead, use: VCR::Config.cassette_library_dir."

    it 'delegates #cache_dir= to #cassette_library_dir=' do
      subject.should_receive(:cassette_library_dir=).with(:value)
      subject.cache_dir = :value
    end

    it "prints a warning: WARNING: VCR::Config.cache_dir= is deprecated.  Instead, use: VCR::Config.cassette_library_dir=." do
      subject.stub!(:cassette_library_dir=)
      subject.should_receive(:warn).with("WARNING: VCR::Config.cache_dir= is deprecated.  Instead, use: VCR::Config.cassette_library_dir=.")
      subject.cache_dir = :value
    end

    describe '#default_cassette_record_mode=' do
      it 'sets the default_cassette_options[:record] option' do
        VCR::Cassette::VALID_RECORD_MODES.each do |mode|
          VCR::Config.default_cassette_options = nil
          VCR::Config.default_cassette_record_mode = mode
          VCR::Config.default_cassette_options[:record].should == mode
        end
      end

      it 'merges the :record option with the existing default_cassette_record options' do
        VCR::Config.default_cassette_options = { :an => :option }
        VCR::Config.default_cassette_record_mode = :all
        VCR::Config.default_cassette_options.should == { :an => :option, :record => :all }
      end

      it 'warns the user that it is deprecated' do
        VCR::Cassette::VALID_RECORD_MODES.each do |mode|
          VCR::Config.should_receive(:warn).with(%Q{WARNING: #default_cassette_record_mode is deprecated.  Instead, use: "default_cassette_options = { :record => :#{mode.to_s} }"})
          VCR::Config.default_cassette_record_mode = mode
        end
      end
    end
  end
end