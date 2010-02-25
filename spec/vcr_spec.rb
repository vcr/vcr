require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR do
  before(:all) do
    @orig_default_cassette_record_mode = VCR::Config.default_cassette_record_mode
    VCR::Config.default_cassette_record_mode = :unregistered
  end

  after(:all) do
    VCR::Config.default_cassette_record_mode = :unregistered
  end

  def create_cassette
    VCR.create_cassette!(:cassette_test)
  end

  describe 'create_cassette!' do
    it 'should create a new cassette' do
      create_cassette.should be_instance_of(VCR::Cassette)
    end

    it 'should take over as the #current_cassette' do
      orig_cassette = VCR.current_cassette
      new_cassette = create_cassette
      new_cassette.should_not == orig_cassette
      VCR.current_cassette.should == new_cassette
    end
  end

  describe 'destroy_cassette!' do
    def destroy_cassette
      VCR.destroy_cassette!
    end

    it 'should destroy the current sandbo' do
      cassette = create_cassette
      cassette.should_receive(:destroy!)
      VCR.destroy_cassette!
    end

    it 'should return the destroyed cassette' do
      cassette = create_cassette
      VCR.destroy_cassette!.should == cassette
    end

    it 'should return the #current_cassette to the previous one' do
      cassette1, cassette2 = create_cassette, create_cassette
      lambda { VCR.destroy_cassette! }.should change(VCR, :current_cassette).from(cassette2).to(cassette1)
    end
  end

  describe 'with_cassette' do
    it 'should create a new cassette' do
      new_cassette = VCR::Cassette.new(:with_cassette_test)
      VCR.should_receive(:create_cassette!).and_return(new_cassette)
      VCR.with_cassette(:cassette_test) { }
    end

    it 'should yield' do
      yielded = false
      VCR.with_cassette(:cassette_test) { yielded = true }
      yielded.should be_true
    end

    it 'should destroy the cassette' do
      VCR.should_receive(:destroy_cassette!)
      VCR.with_cassette(:cassette_test) { }
    end

    it 'should destroy the cassette even if there is an error' do
      VCR.should_receive(:destroy_cassette!)
      lambda { VCR.with_cassette(:cassette_test) { raise StandardError } }.should raise_error
    end
  end

  describe 'config' do
    it 'should yield the configuration object' do
      yielded_object = nil
      VCR.config do |obj|
        yielded_object = obj
      end
      yielded_object.should == VCR::Config
    end
  end

  describe 'cucumber_tags' do
    it 'should yield a cucumber tags object' do
      yielded_object = nil
      VCR.cucumber_tags do |obj|
        yielded_object = obj
      end
      yielded_object.should be_instance_of(VCR::CucumberTags)
    end
  end
end
