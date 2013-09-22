require 'vcr/cassette/persisters'

module VCR
  class Cassette
    describe Persisters do
      describe "#[]=" do
        context 'when there is already a persister registered for the given name' do
          before(:each) do
            subject[:foo] = :old_persister
            allow(subject).to receive :warn
          end

          it 'overrides the existing persister' do
            subject[:foo] = :new_persister
            expect(subject[:foo]).to be(:new_persister)
          end

          it 'warns that there is a name collision' do
            expect(subject).to receive(:warn).with(
              /WARNING: There is already a VCR cassette persister registered for :foo\. Overriding it/
            )
            subject[:foo] = :new_persister
          end
        end
      end

      describe "#[]" do
        it 'raises an error when given an unrecognized persister name' do
          expect { subject[:foo] }.to raise_error(ArgumentError)
        end

        it 'returns the named persister' do
          expect(subject[:file_system]).to be(VCR::Cassette::Persisters::FileSystem)
        end
      end
    end
  end
end

