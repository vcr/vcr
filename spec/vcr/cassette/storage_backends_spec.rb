require 'vcr/cassette/storage_backends'

module VCR
  class Cassette
    describe StorageBackends do
      describe "#[]=" do
        context 'when there is already a storage backend registered for the given name' do
          before(:each) do
            subject[:foo] = :old_backend
            subject.stub :warn
          end

          it 'overrides the existing storage backend' do
            subject[:foo] = :new_backend
            subject[:foo].should be(:new_backend)
          end

          it 'warns that there is a name collision' do
            subject.should_receive(:warn).with(
              /WARNING: There is already a VCR cassette storage backend registered for :foo\. Overriding it/
            )
            subject[:foo] = :new_backend
          end
        end
      end

      describe "#[]" do
        it 'raises an error when given an unrecognized storage backend name' do
          expect { subject[:foo] }.to raise_error(ArgumentError)
        end

        it 'returns the named serializer' do
          subject[:file_system].should be(VCR::Cassette::StorageBackends::FileSystem)
        end
      end
    end
  end
end

