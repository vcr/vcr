require 'spec_helper'

VCR::HttpStubbingAdapters::Common.adapters.each do |adapter|
  describe adapter, 'deprecations' do
    disable_warnings
    it_behaves_like '.ignore_localhost? deprecation'
  end
end
