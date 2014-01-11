require "vcr"
require "minitest/autorun"
require "minispec-metadata"
require "mocha"

VCR.configuration.configure_minitest_metadata!

describe VCR::MiniTest::Spec do

  before do
    FileUtils.stubs(:mkdir_p).with("test/cassettes").returns(true)
  end

  describe 'an example group', :vcr do
    describe 'with a nested example group' do
      it 'uses a cassette for any examples' do
        VCR.current_cassette.name.must_equal 'uses_a_cassette_for_any_examples'
      end
    end
  end
end
# describe "simple failing test", vcr: true do

#   before do
#     FileUtils.expects(:mkdir_p).with("test/cassettes").returns(true)
#   end

#   it "makes this the name" do
#     VCR.current_cassette.name.split('/').must_equal([
#       'VCR::RSpec::Metadata',
#       'an example group',
#       'with a nested example group',
#       'uses a cassette for any examples'
#     ])
#   end
# end
