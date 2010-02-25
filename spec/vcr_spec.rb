require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR do
  def create_sandbox
    VCR.create_sandbox!(:sandbox_test, :record => :all)
  end

  describe 'create_sandbox!' do
    it 'should create a new sandbox' do
      create_sandbox.should be_instance_of(VCR::Sandbox)
    end

    it 'should take over as the #current_sandbox' do
      orig_sandbox = VCR.current_sandbox
      new_sandbox = create_sandbox
      new_sandbox.should_not == orig_sandbox
      VCR.current_sandbox.should == new_sandbox
    end
  end

  describe 'destroy_sandbox!' do
    def destroy_sandbox
      VCR.destroy_sandbox!
    end

    it 'should destroy the current sandbo' do
      sandbox = create_sandbox
      sandbox.should_receive(:destroy!)
      VCR.destroy_sandbox!
    end

    it 'should return the destroyed sandbox' do
      sandbox = create_sandbox
      VCR.destroy_sandbox!.should == sandbox
    end

    it 'should return the #current_sandbox to the previous one' do
      sandbox1, sandbox2 = create_sandbox, create_sandbox
      lambda { VCR.destroy_sandbox! }.should change(VCR, :current_sandbox).from(sandbox2).to(sandbox1)
    end
  end

  describe 'with_sandbox' do
    it 'should create a new sandbox' do
      new_sandbox = VCR::Sandbox.new(:with_sandbox_test)
      VCR.should_receive(:create_sandbox!).and_return(new_sandbox)
      VCR.with_sandbox(:sandbox_test) { }
    end

    it 'should yield' do
      yielded = false
      VCR.with_sandbox(:sandbox_test) { yielded = true }
      yielded.should be_true
    end

    it 'should destroy the sandbox' do
      VCR.should_receive(:destroy_sandbox!)
      VCR.with_sandbox(:sandbox_test) { }
    end

    it 'should destroy the sandbox even if there is an error' do
      VCR.should_receive(:destroy_sandbox!)
      lambda { VCR.with_sandbox(:sandbox_test) { raise StandardError } }.should raise_error
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
