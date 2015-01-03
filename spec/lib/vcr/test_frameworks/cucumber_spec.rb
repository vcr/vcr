require 'spec_helper'

describe VCR::CucumberTags do
  subject { described_class.new(self) }
  let(:before_blocks_for_tags) { {} }
  let(:after_blocks_for_tags) { {} }

  def scenario(name)
    double(:name => name, :feature => double(:name => "My feature name\nThe preamble text is not included"), :failed? => false)
  end

  let(:current_scenario) { scenario "My scenario name\nThe preamble text is not included" }

  # define our own Before/After so we can test this in isolation from cucumber's implementation.
  def Before(tag, &block)
    before_blocks_for_tags[tag.sub('@', '')] = block
  end

  def After(tag, &block)
    after_blocks_for_tags[tag.sub('@', '')] = block
  end

  def test_tag(cassette_attribute, tag, expected_value, scenario=current_scenario)
    expect(VCR.current_cassette).to be_nil

    before_blocks_for_tags[tag].call(scenario)
    expect(VCR.current_cassette.send(cassette_attribute)).to eq(expected_value)
    after_blocks_for_tags[tag].call(scenario)

    expect(VCR.current_cassette).to be_nil
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

      context 'with :use_scenario_name as an option' do
        it "uses the scenario's name as the cassette name" do
          subject.send(tag_method, 'tag1', :use_scenario_name => true)

          test_tag(:name, 'tag1', 'My feature name/My scenario name')
        end

        it "makes a unique name for each element of scenario outline" do
          subject.send(tag_method, 'tag1', :use_scenario_name => true)

          scenario_with_outline = double(:name => "My row name", :failed? => false,
                                       :scenario_outline => double(:feature => double(:name => "My feature name\nThe preamble text is not included"),
                                                                 :name => "My scenario outline name"))
          test_tag(:name, 'tag1', 'My feature name/My scenario outline name/My row name', scenario_with_outline)
        end

        it 'does not pass :use_scenario_name along the given options to the cassette' do
          subject.send(tag_method, 'tag1', :use_scenario_name => true)

          expect(VCR::Cassette).to receive(:new).with(anything, hash_not_including(:use_scenario_name))
          before_blocks_for_tags['tag1'].call(current_scenario)
        end

        it 'does not modify the options passed to the cassette' do
          original_options = { :use_scenario_name => true, :record => :none }
          subject.send(tag_method, 'tag1', original_options)
          before_blocks_for_tags['tag1'].call(current_scenario)

          expect(original_options.size).to eq(2)
          expect(original_options[:use_scenario_name]).to eq(true)
          expect(original_options[:record]).to eq(:none)
        end

        it "works properly when multiple scenarios use the tag" do
          subject.send(tag_method, 'tag1', :use_scenario_name => true)

          test_tag(:name, 'tag1', 'My feature name/Foo', scenario("Foo"))
          test_tag(:name, 'tag1', 'My feature name/Bar', scenario("Bar"))
        end
      end
    end
  end

  describe '.tags' do
    it 'returns the list of cucumber tags' do
      subject.tags 'tag1', 'tag2'
      subject.tags 'tag3', 'tag4'
      expect(described_class.tags[-4, 4]).to eq(%w(@tag1 @tag2 @tag3 @tag4))
    end
  end
end
