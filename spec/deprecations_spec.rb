require 'spec_helper'

describe 'Deprecations' do
  describe VCR do
    subject { VCR }
    deprecated :create_cassette!,  :insert_cassette, "WARNING: VCR.create_cassette! is deprecated.  Instead, use: VCR.insert_cassette."
    deprecated :destroy_cassette!, :eject_cassette,  "WARNING: VCR.destroy_cassette! is deprecated.  Instead, use: VCR.eject_cassette."
    deprecated :with_cassette,     :use_cassette,    "WARNING: VCR.with_cassette! is deprecated.  Instead, use: VCR.use_cassette."
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
  end
end