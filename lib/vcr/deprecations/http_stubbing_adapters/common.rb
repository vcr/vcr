module VCR
  module HttpStubbingAdapters
    module Common
      def ignore_localhost?
        VCR::Config.ignore_localhost?
      end
    end
  end
end
