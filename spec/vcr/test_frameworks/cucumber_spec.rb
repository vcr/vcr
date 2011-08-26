require 'spec_helper'

describe VCR::CucumberTags do
  subject { described_class.new(self) }
  let(:before_blocks_for_tags) { {} }
  let(:after_blocks_for_tags) { {} }

  # define our own Before/After so we can test this in isolation from cucumber's implementation.
  def Before(tag, &block)
    before_blocks_for_tags[tag.sub('@', '')] = block
  end

  def After(tag, &block)
    after_blocks_for_tags[tag.sub('@', '')] = block
  end

  def test_tag(cassette_attribute, tag, expected_value)
    VCR.current_cassette.should be_nil

    before_blocks_for_tags[tag].call
    VCR.current_cassette.send(cassette_attribute).should eq(expected_value)
    after_blocks_for_tags[tag].call

    VCR.current_cassette.should be_nil
  end

  %w(tags tag).each do |tag_method|
    describe "##{tag_method}" do
      it "creates a cucumber Around hook for each given tag so that the scenario runs with the cassette inserted" do
        subject.send(tag_method, 'tag1', 'tag2')

        test_tag(:name, 'tag1', 'cucumber_tags/tag1')
        test_tag(:name, 'tag2', 'cucumber_tags/tag2')
      end

      it "works with tags that start with an @" do
        subject.send(tag_method, '@tag1', '@tag2')

        test_tag(:name, 'tag1', 'cucumber_tags/tag1')
        test_tag(:name, 'tag2', 'cucumber_tags/tag2')
      end

      it "passes along the given options to the cassette" do
        subject.send(tag_method, 'tag1', :record => :none)
        subject.send(tag_method, 'tag2', :record => :new_episodes)

        test_tag(:record_mode, 'tag1', :none)
        test_tag(:record_mode, 'tag2', :new_episodes)
      end
    end
  end

  describe '.tags' do
    it 'returns the list of cucumber tags' do
      subject.tags 'tag1', 'tag2'
      subject.tags 'tag3', 'tag4'
      described_class.tags[-4, 4].should eq(%w(@tag1 @tag2 @tag3 @tag4))
    end
  end
end
