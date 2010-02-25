require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VCR::CucumberTags do
  before(:each) do
    @args =   { :before => [], :after => [] }
    @blocks = { :before => [], :after => [] }
  end

  def Before(*args, &block)
    @args[:before]   << args
    @blocks[:before] << block
  end

  def After(*args, &block)
    @args[:after]   << args
    @blocks[:after] << block
  end

  describe '#tag' do
    [:before, :after].each do |hook|
      it "sets up a cucumber #{hook} hook for the given tag that creates a new cassette" do
        VCR.cucumber_tags { |t| t.tag 'tag_test' }

        @args[hook].should == [['@tag_test']]

        if hook == :before
          VCR.should_receive(:create_cassette!).with('cucumber_tags/tag_test', {})
        else
          VCR.should_receive(:destroy_cassette!)
        end
        @blocks[hook].should have(1).block
        @blocks[hook].first.call
      end

      it "sets up separate hooks for each tag, passing the given options to each cassette" do
        VCR.cucumber_tags { |t| t.tag 'tag_test1', 'tag_test2', :record => :none }
        @args[hook].should == [['@tag_test1'], ['@tag_test2']]

        if hook == :before
          VCR.should_receive(:create_cassette!).with('cucumber_tags/tag_test1', { :record => :none }).once
          VCR.should_receive(:create_cassette!).with('cucumber_tags/tag_test2', { :record => :none }).once
        else
          VCR.should_receive(:destroy_cassette!).twice
        end
        @blocks[hook].should have(2).blocks
        @blocks[hook].each { |b| b.call }
      end

      it "works with tags that start with an @" do
        VCR.cucumber_tags { |t| t.tag '@tag_test' }
        @args[hook].should == [['@tag_test']]

        if hook == :before
          VCR.should_receive(:create_cassette!).with('cucumber_tags/tag_test', {})
        else
          VCR.should_receive(:destroy_cassette!)
        end
        @blocks[hook].should have(1).block
        @blocks[hook].first.call
      end
    end
  end

  describe '.tags' do
    it 'returns the list of cucumber tags' do
      VCR.cucumber_tags { |t| t.tag 'tag1' }
      VCR.cucumber_tags { |t| t.tags 'tag7', 'tag12' }
      VCR::CucumberTags.tags[-3, 3].should == %w(@tag1 @tag7 @tag12)
    end
  end
end