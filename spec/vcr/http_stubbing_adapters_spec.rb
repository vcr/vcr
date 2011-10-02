require 'vcr/http_stubbing_adapters'

module VCR
  describe HTTPStubbingAdapters do
    describe '#disabled?' do
      it 'returns false by default for any argument given' do
        subject.disabled?(:foo).should be_false
        subject.disabled?(:bar).should be_false
      end

      context 'when an adapter is exclusively enabled' do
        it 'returns false for the exclusively enabled adapter' do
          faraday_disabled = nil

          subject.exclusively_enabled :faraday do
            faraday_disabled = subject.disabled?(:faraday)
          end

          faraday_disabled.should eq(false)
        end

        it 'returns true for every other argument given' do
          foo_disabled = bar_disabled = nil

          subject.exclusively_enabled :faraday do
            foo_disabled = subject.disabled?(:foo)
            bar_disabled = subject.disabled?(:bar)
          end

          foo_disabled.should be_true
          bar_disabled.should be_true
        end
      end
    end

    describe '#exclusively_enabled' do
      it 'restores all adapters to being enabled when the block completes' do
        subject.exclusively_enabled(:faraday) { }
        subject.disabled?(:foo).should be_false
        subject.disabled?(:faraday).should be_false
      end

      it 'restores all adapters to being enabled when the block completes, even if there is an error' do
        subject.exclusively_enabled(:faraday) { raise "boom" } rescue
        subject.disabled?(:foo).should be_false
        subject.disabled?(:faraday).should be_false
      end
    end
  end
end

