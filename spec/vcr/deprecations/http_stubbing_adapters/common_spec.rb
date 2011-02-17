require 'spec_helper'

VCR::HttpStubbingAdapters::Common.adapters.each do |adapter|
  describe adapter, 'deprecations', :disable_warnings => true do
    it_behaves_like '.ignore_localhost? deprecation'
  end
end
